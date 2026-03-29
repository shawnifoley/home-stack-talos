# Longhorn DR Runbook (Fresh Cluster)

## Scope

- Restore app data for:
  - `sonarr-config`
  - `radarr-config`
  - `vaultwarden-data`
  - `mealie-data`
- Reconnect workloads in namespace `media`
- Re-enable recurring Longhorn backups
- Cut traffic over after validation

## 1) Bootstrap core manifests

Apply infra first (includes Longhorn backup target + recurring jobs):

```bash
kubectl apply -k k8s/infra
```

Check backup target health:

```bash
kubectl -n longhorn-system get backuptargets.longhorn.io default -o wide
```

Expected: `AVAILABLE=true`.

## 2) Verify backups are visible

```bash
kubectl -n longhorn-system get backupvolumes.longhorn.io
kubectl -n longhorn-system get backups.longhorn.io -o wide
```

Expected: backup objects exist for Sonarr, Radarr, Vaultwarden, and Mealie.

Apply stack and take services down

```bash
kubectl apply -k k8s/media-stack/overlays/prod
```

Scale workloads down before restore:

```
kubectl -n media scale deploy vaultwarden --replicas=0
kubectl -n media scale deploy sonarr --replicas=0
kubectl -n media scale deploy radarr --replicas=0
kubectl -n media scale deploy mealie --replicas=0
```

## 3) Restore volumes from Longhorn backups

Use Longhorn UI (`Backup` page):
```bash
kubectl -n longhorn-system port-forward svc/longhorn-frontend 8080:80
```

1. Delete `detached` volumes (vaultwarden, sonarr, radarr, mealie)
2. Restore each backup to a new Longhorn volume.
3. For each restored volume, go to `Operation` -> `Create PV/PVC` action and create PVCs in namespace `media`.

## 4) Bring workloads back with restored volumes

```bash
kubectl -n media scale deploy vaultwarden --replicas=1
kubectl -n media scale deploy sonarr --replicas=1
kubectl -n media scale deploy radarr --replicas=1
kubectl -n media scale deploy mealie --replicas=1
```

## 5) Re-attach recurring backups to restored volumes

Map PVCs to Longhorn volume names:

```bash
kubectl -n media get pvc sonarr-config radarr-config vaultwarden-data mealie-data \
  -o custom-columns=PVC:.metadata.name,VOLUME:.spec.volumeName
```

Label each Longhorn `Volume` CR (one-time attach):

```bash
kubectl -n longhorn-system label volumes.longhorn.io <sonarr-volume-name> \
  recurring-job.longhorn.io/source=enabled \
  recurring-job.longhorn.io/backup-sonarr-weekly=enabled --overwrite

kubectl -n longhorn-system label volumes.longhorn.io <radarr-volume-name> \
  recurring-job.longhorn.io/source=enabled \
  recurring-job.longhorn.io/backup-radarr-weekly=enabled --overwrite

kubectl -n longhorn-system label volumes.longhorn.io <vaultwarden-volume-name> \
  recurring-job.longhorn.io/source=enabled \
  recurring-job.longhorn.io/backup-vaultwarden-daily=enabled --overwrite

kubectl -n longhorn-system label volumes.longhorn.io <mealie-volume-name> \
  recurring-job.longhorn.io/source=enabled \
  recurring-job.longhorn.io/backup-mealie-weekly=enabled --overwrite
```

Or use this helper script to set volume names once and attach all jobs:

```bash
#!/usr/bin/env bash
set -euo pipefail

NS="longhorn-system"

# Set these to the Longhorn volume names from the PVC mapping output.
SONARR_VOL="<sonarr-volume-name>"
RADARR_VOL="<radarr-volume-name>"
VAULTWARDEN_VOL="<vaultwarden-volume-name>"
MEALIE_VOL="<mealie-volume-name>"

attach_job() {
  local volume_name="$1"
  local job_name="$2"
  kubectl -n "${NS}" label "volumes.longhorn.io/${volume_name}" \
    recurring-job.longhorn.io/source=enabled \
    "recurring-job.longhorn.io/${job_name}=enabled" \
    --overwrite
}

attach_job "${SONARR_VOL}" "backup-sonarr-weekly"
attach_job "${RADARR_VOL}" "backup-radarr-weekly"
attach_job "${VAULTWARDEN_VOL}" "backup-vaultwarden-daily"
attach_job "${MEALIE_VOL}" "backup-mealie-weekly"
```

## 6) Validate end state

```bash
kubectl get pods -n media
kubectl rollout status deployment/sonarr -n media
kubectl rollout status deployment/radarr -n media
kubectl rollout status deployment/vaultwarden -n media
kubectl rollout status deployment/mealie -n media
kubectl -n longhorn-system get backups.longhorn.io -o wide
kubectl -n longhorn-system get recurringjobs.longhorn.io
```

Smoke checks:

- App UIs reachable via ingress
- App data/state is present
- New backups continue to appear in Longhorn

## 7) Cutover checklist

- DNS points to new cluster ingress
- TLS certs are valid
- Longhorn backups are succeeding
- Old cluster left powered down but recoverable until confidence window ends

# Talos Fresh Cutover Runbook

This runbook is for a full fresh-cluster rebuild on Talos, restoring app data from existing Longhorn backups.

## Scope

- Build a brand-new Talos Kubernetes cluster.
- Reuse this repo's manifests for infra and workloads.
- Restore app data from Longhorn backup target.
- Cut traffic over after validation.

## 1) Bring up Talos cluster

Prerequisites:

- `talosctl` configured for the new nodes.
- Kubernetes API reachable.
- Storage disks ready for Longhorn.

Validation:

```bash
kubectl get nodes -o wide
kubectl get pods -A
```

## 2) Apply infra and verify Longhorn backup target

```bash
kubectl apply -k k8s/infra

kubectl -n longhorn-system get pods
kubectl -n longhorn-system get backuptargets.longhorn.io default -o wide
kubectl -n longhorn-system describe backuptargets.longhorn.io default
```

Expected: `AVAILABLE=true` on backup target.

## 3) Confirm backup metadata is visible

```bash
kubectl -n longhorn-system get backupvolumes.longhorn.io
kubectl -n longhorn-system get backups.longhorn.io -o wide
```

Expected: backup sets exist for `sonarr-config`, `radarr-config`, `vaultwarden-data`, and `mealie-data`.

## 4) Apply workloads and scale down before restore

```bash
kubectl apply -k k8s/media-stack/overlays/prod

kubectl -n media scale deploy sonarr --replicas=0
kubectl -n media scale deploy radarr --replicas=0
kubectl -n media scale deploy vaultwarden --replicas=0
kubectl -n media scale deploy mealie --replicas=0
```

## 5) Restore volumes from Longhorn UI

```bash
kubectl -n longhorn-system port-forward svc/longhorn-frontend 8080:80
```

In Longhorn UI:

1. Open `Backup` page.
2. Restore each app volume backup to a Longhorn volume.
3. For each restored volume, create PV/PVC in namespace `media` with original claim names:
   - `sonarr-config`
   - `radarr-config`
   - `vaultwarden-data`
   - `mealie-data`

## 6) Re-attach recurring backup jobs to restored Longhorn volumes

Map PVC to volume names:

```bash
kubectl -n media get pvc sonarr-config radarr-config vaultwarden-data mealie-data \
  -o custom-columns=PVC:.metadata.name,VOLUME:.spec.volumeName
```

Attach labels:

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

## 7) Bring workloads online and validate

```bash
kubectl -n media scale deploy sonarr --replicas=1
kubectl -n media scale deploy radarr --replicas=1
kubectl -n media scale deploy vaultwarden --replicas=1
kubectl -n media scale deploy mealie --replicas=1

kubectl rollout status deployment/sonarr -n media
kubectl rollout status deployment/radarr -n media
kubectl rollout status deployment/vaultwarden -n media
kubectl rollout status deployment/mealie -n media
```

Smoke checks:

- App UIs reachable via ingress.
- App data/state is present.
- New backups continue to appear in Longhorn.

## 8) Cutover checklist

- DNS points to new cluster ingress.
- TLS certs are valid.
- Longhorn backups are succeeding.
- Old cluster left powered down but recoverable until confidence window ends.

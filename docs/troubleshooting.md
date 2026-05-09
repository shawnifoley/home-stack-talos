# Troubleshooting

This runbook covers the most common issues in this repo's k8s/Longhorn stack.

## 1) Render/apply failures

Validate manifests first:

```bash
kubectl kustomize k8s/infra
kubectl kustomize k8s/media-stack
```

Apply in order:

```bash
kubectl apply -k k8s/infra
kubectl apply -k k8s/media-stack
```

## 2) Pods Pending (PVC or storage issues)

Check claims and volumes:

```bash
kubectl get pvc,pv -n media
kubectl describe pvc -n media <pvc-name>
kubectl describe pv <pv-name>
```

Common causes:

- PV is already bound to a different PVC
- `storageClassName` mismatch between PVC and available provisioner
- static PV `mountOptions` mismatch for NFS server

## 3) Longhorn backup target unavailable

Check target:

```bash
kubectl -n longhorn-system get backuptargets.longhorn.io default -o wide
kubectl -n longhorn-system describe backuptargets.longhorn.io default
```

If `AVAILABLE=false`, verify:

- NFS path exists and is writable
- NFS protocol/options match server support
- Longhorn manager logs show successful mount

```bash
kubectl -n longhorn-system logs -l app=longhorn-manager --tail=300 | rg -i "backup|nfs|mount|error|failed"
```

## 4) Recurring jobs exist but no backups are created

Check recurring jobs and backups:

```bash
kubectl -n longhorn-system get recurringjobs.longhorn.io
kubectl -n longhorn-system get backups.longhorn.io -o wide
```

Check per-volume labels (one-time attach for existing volumes):

```bash
kubectl -n media get pvc sonarr-config radarr-config vaultwarden-data mealie-data \
  -o custom-columns=PVC:.metadata.name,VOLUME:.spec.volumeName
kubectl -n longhorn-system get volumes.longhorn.io <volume-name> -o yaml | rg -n "recurring-job.longhorn.io|backup-target"
```

Expected volume labels include:

- `recurring-job.longhorn.io/source=enabled`
- one job label (for example `recurring-job.longhorn.io/backup-vaultwarden-daily=enabled`)

## 5) Rollout not progressing

```bash
kubectl rollout status deployment/<name> -n media
kubectl describe deployment/<name> -n media
kubectl get pods -n media
kubectl logs -n media <pod-name> --previous
```

For Vaultwarden updates, deployment uses `Recreate`; brief downtime is expected during rollout.

## 6) Ingress or TLS failures

```bash
kubectl get ingress -n media
kubectl describe ingress <name> -n media
kubectl get certificate,certificaterequest -n media
kubectl get challenge,order -n media
```

Also verify DNS:

```bash
dig +short sabnzbd.fol3y.us
dig +short sonarr.fol3y.us
dig +short radarr.fol3y.us
dig +short vaultwarden.fol3y.us
dig +short mealie.fol3y.us
```

## 7) Useful UI port-forwards

```bash
kubectl -n longhorn-system port-forward svc/longhorn-frontend 8080:80
kubectl -n kube-system port-forward svc/traefik 9000:9000
```

## 8) If this runbook does not resolve it

Capture and share:

```bash
kubectl get events -A --sort-by=.lastTimestamp | tail -n 100
kubectl get pods -A -o wide
```

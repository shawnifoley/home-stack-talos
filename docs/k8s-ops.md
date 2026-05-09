# Kubernetes Ops

## Deploy Order

```bash
kubectl apply -k k8s/infra
kubectl apply -k k8s/media-stack
```

## Validate

```bash
kubectl kustomize k8s/infra
kubectl kustomize k8s/media-stack

kubectl rollout status deployment/sabnzbd -n media
kubectl rollout status deployment/sonarr -n media
kubectl rollout status deployment/radarr -n media
kubectl rollout status deployment/vaultwarden -n media
kubectl rollout status deployment/mealie -n media
```

## Access UIs

```bash
kubectl -n longhorn-system port-forward svc/longhorn-frontend 8080:80
kubectl -n kube-system port-forward svc/traefik 9000:9000
```

## Monitoring

Install monitoring stack and rules:

```bash
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f k8s/monitoring/kube-prometheus-stack-values.yaml

kubectl apply -k k8s/monitoring
```

Runbook: [k8s/monitoring/README.md](../k8s/monitoring/README.md)

## Longhorn Backups

Recurring jobs and backup target are managed in `k8s/infra`.

Check:

```bash
kubectl -n longhorn-system get backuptargets.longhorn.io default -o wide
kubectl -n longhorn-system get recurringjobs.longhorn.io
kubectl -n longhorn-system get backups.longhorn.io -o wide
```

### Existing volumes: one-time recurring-job attach

```bash
kubectl -n media get pvc sonarr-config radarr-config vaultwarden-data mealie-data \
  -o custom-columns=PVC:.metadata.name,VOLUME:.spec.volumeName

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

## Restore

See [docs/longhorn-dr-runbook.md](longhorn-dr-runbook.md).

## Troubleshooting

See [docs/troubleshooting.md](troubleshooting.md).

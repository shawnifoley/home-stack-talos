# Media Stack (Kustomize)

This folder organizes Sabnzbd, Sonarr, Radarr, Vaultwarden, and Mealie into a reusable base with a prod overlay.

## Apply

```bash
kubectl apply -k k8s/media-stack
```

## Preview

```bash
kubectl kustomize k8s/media-stack
```

## Layout

- `base/`: reusable manifests for apps and storage.
- `overlays/prod/`: cluster-specific values (hosts, ingress class, issuer, image policy).
- `overlays/prod/extras/`: optional/cluster-local extras such as scheduled rollout restarts.

## Backup Behavior

- Longhorn recurring backups are managed in `k8s/infra`.
- For operational commands and one-time volume attach steps, use [docs/k8s-ops.md](../../docs/k8s-ops.md).

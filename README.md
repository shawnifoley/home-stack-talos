# home-stack

Single repo for home-cluster provisioning and workloads:

- Provisioning: Tofu + Talosctl (Ansible optional for postconfig)
- Platform/workloads: Kubernetes manifests + ArgoCD apps
- Data protection: Longhorn recurring backups + DR runbook

## Start Here

1. Bootstrap nodes and Talos Kubernetes: [docs/bootstrap-tofu-ansible.md](docs/bootstrap-tofu-ansible.md)
2. Deploy platform/workloads: [docs/k8s-ops.md](docs/k8s-ops.md)
3. Configure and validate backups: [docs/k8s-ops.md#longhorn-backups](docs/k8s-ops.md#longhorn-backups)
4. Restore on a fresh cluster: [docs/longhorn-dr-runbook.md](docs/longhorn-dr-runbook.md)
5. Troubleshooting: [docs/troubleshooting.md](docs/troubleshooting.md)

## Repo Map

- `tofu/`: infrastructure provisioning
- `ansible/`: optional post-bootstrap platform configuration
- `k8s/infra/`: cluster-level resources (Longhorn/NFS/cert-manager)
- `k8s/media-stack/`: app stack manifests (Sabnzbd/Sonarr/Radarr/Vaultwarden/Mealie)
- `k8s/slurm-stack/`: Slurm playground manifests
- `k8s/argocd/`: ArgoCD `Application` definitions
- `docs/`: operational runbooks

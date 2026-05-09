# Slurm Stack (Kustomize)

Lightweight Slurm playground stack for Kubernetes.

## Apply

```bash
make k8s-apply-slurm
```

## Preview

```bash
kubectl kustomize k8s/slurm-stack
```

## Notes

- This is a lab baseline for experimenting, not a hardened production Slurm deployment.
- `munge-secret.example.yaml` is a template only.
- `make k8s-apply-slurm` auto-generates/rotates the in-cluster `munge-key` secret.
- Current image: `ghcr.io/giovtorres/slurm-docker-cluster:latest`.

## Login Workflow

Use the dedicated login pod for `srun`, `sbatch`, and `squeue`:

```bash
kubectl -n slurm get pods
kubectl -n slurm exec -it deploy/slurm-login -- bash
```

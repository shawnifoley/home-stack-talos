# Slurm Stack (Kustomize)

Lightweight Slurm playground stack for Kubernetes.

## Apply

```bash
kubectl apply -k k8s/slurm-stack
```

## Preview

```bash
kubectl kustomize k8s/slurm-stack
```

## Notes

- This is a lab baseline for experimenting, not a hardened production Slurm deployment.
- Set a real `munge.key` in `munge-secret.yaml` before use.
- Current image: `ghcr.io/giovtorres/slurm-docker-cluster:latest`.

## Login Workflow

Use the dedicated login pod for `srun`, `sbatch`, and `squeue`:

```bash
kubectl -n slurm get pods
kubectl -n slurm exec -it deploy/slurm-login -- bash
```

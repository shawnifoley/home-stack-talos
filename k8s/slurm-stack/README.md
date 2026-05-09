# Slurm Stack (Kustomize)

Lightweight Slurm playground stack for Kubernetes.

## Apply

```bash
make k8s-apply-slurm K8S_ENV=dev SLURM_SSH_PUBKEY_PATH=$HOME/.ssh/id_ed25519.pub
```

## Preview

```bash
kubectl kustomize k8s/slurm-stack
```

## Notes

- This is a lab baseline for experimenting, not a hardened production Slurm deployment.
- `munge-secret.example.yaml` is a template only.
- `make k8s-apply-slurm` auto-generates/rotates the in-cluster `munge-key` secret.
- `make k8s-apply-slurm` creates/updates `slurm-login-authorized-key` from `SLURM_SSH_PUBKEY_PATH`.
- Default login user is `sfoley` with UID `1000`.
- Current image: `giovtorres/slurm-docker-cluster:latest`.
- Shared home is mounted at `/home` using NFS PV `slurm-home` (`/tank/slurm-home` on `192.168.1.202`).

## Login Workflow

Use the dedicated login pod for `srun`, `sbatch`, and `squeue`:

```bash
kubectl -n slurm get pods
kubectl -n slurm exec -it deploy/slurm-login -- bash
```

SSH is also exposed through NodePort `30022`:

```bash
kubectl -n slurm get svc slurm-login-ssh
ssh sfoley@<node-ip> -p 30022
```

Password SSH auth is disabled; key-based auth is required.

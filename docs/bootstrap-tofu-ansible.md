# Bootstrap (Tofu + Talosctl)

This runbook builds Proxmox VMs with Tofu, bootstraps Talos Kubernetes with `talosctl`, then applies optional platform components.

## Prereqs

- Proxmox API access
- `tofu`, `kubectl`, `talosctl`
- environment vars for Proxmox auth (for example `TF_VAR_pm_api_password`)

## Proxmox Template Setup (One-Time)

Create a Talos VM template in Proxmox and set `template_id` in `tofu/variables.*.tfvars` to that template.

This bootstrap is Talos-native: Tofu does not use cloud-init.
Set `controlplane_ips`/`worker_ips` to the node addresses you expect Talos to use (typically via DHCP reservations).

## 1) Tofu (provision Talos VMs)

Per environment:

```bash
cd tofu
tofu init
tofu plan --var-file=variables.dev.tfvars
tofu apply --var-file=variables.dev.tfvars
```

Make targets:

```bash
make tofu-plan-dev
make tofu-apply-dev
make tofu-plan-prod
make tofu-apply-prod
```

Outputs:

- `ansible/inventory/dev/hosts.ini`
- `ansible/inventory/prod/hosts.ini`

## 2) Talos bootstrap (talosctl)

Bootstrap settings are managed via Ansible inventory/group vars:

- `ansible/inventory/dev/group_vars/all.yml`
- `ansible/inventory/prod/group_vars/all.yml`

### Talos system extensions

For extensions such as:

```yaml
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/iscsi-tools
      - siderolabs/qemu-guest-agent
      - siderolabs/util-linux-tools
```

build a Talos Image Factory schematic/image and set `talos_install_image` in `ansible/inventory/*/group_vars/all.yml`.

Run:

```bash
make talos-dev
```

Make targets:

```bash
make talos-dev
make talos-prod
```

Expected:

- Talos configs generated under `~/.talos/<cluster-name>/`
- per-node DHCP -> static mapping applied from Tofu inventory data
- cluster bootstrapped via Talos
- kubeconfig written to `~/.kube/kubeconfig-{dev|prod}.yaml`

## 3) Optional platform components (Ansible postconfig)

Apply optional components with Ansible:

```bash
make postconfig-dev
make postconfig-prod
```

## 4) Cert-manager

Install cert-manager via postconfig:

```bash
make postconfig-dev
make postconfig-prod
```

Optional Cloudflare token secret for DNS-01:

```bash
export CLOUDFLARE_API_TOKEN="<token>"
make postconfig-dev
```

`ClusterIssuer` is applied from `k8s/infra/cluster-issuer-cloudflare.yaml`.

## 5) Postconfig feature flags

Flags:

- ArgoCD:
  - `argocd: true|false`
  - `argocd_version: "<tag>"`
  - `argocd_domain: "<fqdn>"`
- Traefik via Helm:
  - `traefik: true|false`
  - `traefik_chart_version: "<chart-version>"`
- Longhorn via Helm:
  - `longhorn: true|false`
  - `longhorn_chart_version: "<chart-version>"`
- Monitoring via Helm:
  - `monitoring: true|false`
  - `monitoring_chart_version: "<chart-version>"`
- MetalLB:
  - `metallb: true|false`
  - `metallb_version: "<tag>"`
  - `metallb_range: "<start-ip>-<end-ip>"`

These are set per environment in:

- `ansible/inventory/dev/group_vars/all.yml`
- `ansible/inventory/prod/group_vars/all.yml`

## 6) Next step

Deploy manifests via [docs/k8s-ops.md](k8s-ops.md).

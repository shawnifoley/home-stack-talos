pm_host              = "pve.fol3y.us"
pm_node_name         = "pve"
deployment_name      = "prod"
cpu_cores            = 6
pm_tls_insecure      = true
template_id          = 9000
num_controlplane_mem = 24576
num_worker_mem       = 10240
disk_size            = 50
pool_id              = "production"
tags                 = ["production", "k8s"]

# Set credentials via environment variables (recommended):
# export TF_VAR_pm_api_password="..."

controlplane_ips = [
  "192.168.1.21",
]
controlplane_macs = [
]
worker_ips = [
]
worker_macs = [
]

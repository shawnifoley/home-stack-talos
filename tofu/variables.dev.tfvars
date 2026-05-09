pm_host              = "pve.fol3y.us"
pm_node_name         = "pve"
deployment_name      = "dev"
template_id          = 9000
cpu_cores            = 4
num_controlplane_mem = 5120
num_worker_mem       = 5120
disk_size            = 50
datastore            = "local-zfs"
pool_id              = "dev"
tags                 = ["dev", "k8s", "slurm"]

controlplane_ips = [
  "192.168.1.22"
]
worker_ips = [
  "192.168.1.23",
  "192.168.1.24"
]

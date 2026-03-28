pm_host              = "pve.fol3y.us"
pm_node_name         = "sandbox"
deployment_name      = "dev"
template_id          = 9001
cpu_cores            = 4
num_controlplane_mem = 10240
num_worker_mem       = 6120
disk_size            = 50
datastore            = "local-zfs"
pool_id              = "dev"
tags                 = ["dev", "k8s"]

controlplane_ips = [
  "192.168.1.24"
]
worker_ips = [
]

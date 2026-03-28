variable "pm_user" {
  description = "The username for the proxmox user"
  type        = string
  sensitive   = false
  default     = "root@pam"

}
variable "pm_api_password" {
  description = "The password for the proxmox API user"
  type        = string
  sensitive   = true
}

variable "pm_tls_insecure" {
  description = "Set to true to ignore certificate errors"
  type        = bool
  default     = false
}

variable "pm_host" {
  description = "The hostname or IP of the proxmox server"
  type        = string
}

variable "pm_node_name" {
  description = "name of the proxmox node to create the VMs on"
  type        = string
  default     = "pve"
}

variable "deployment_name" {
  description = "Deployment/environment name used for VM naming and inventory output (e.g. dev, prod)"
  type        = string
  default     = "dev"
}

variable "cpu_cores" {
  type    = number
  default = 2
}

variable "cpu_type" {
  type    = string
  default = "x86-64-v2"
}

variable "num_controlplane_mem" {
  type    = number
  default = 4096
}

variable "num_worker_mem" {
  type    = number
  default = 4096
}

variable "template_id" {
  type    = number
  default = 1002
}
variable "pool_id" {
  type = string
}

variable "tags" {
  type = list(string)
}

variable "controlplane_ips" {
  type        = list(string)
  description = "List of IP addresses for Talos control plane nodes"
}

variable "controlplane_macs" {
  type        = list(string)
  description = "Optional MAC addresses for control plane nodes; must match controlplane_ips order"
  default     = []
  validation {
    condition     = length(var.controlplane_macs) == 0 || length(var.controlplane_macs) == length(var.controlplane_ips)
    error_message = "controlplane_macs must be empty or match the length of controlplane_ips."
  }
}

variable "worker_ips" {
  type        = list(string)
  description = "List of ip addresses for worker nodes"
}

variable "worker_macs" {
  type        = list(string)
  description = "Optional MAC addresses for worker nodes; must match worker_ips order"
  default     = []
  validation {
    condition     = length(var.worker_macs) == 0 || length(var.worker_macs) == length(var.worker_ips)
    error_message = "worker_macs must be empty or match the length of worker_ips."
  }
}

variable "net_bridge" {
  type    = string
  default = "vmbr0"
}

variable "datastore" {
  type    = string
  default = "local-lvm"
}

variable "disk_interface" {
  type    = string
  default = "scsi0"
}

variable "disk_discard" {
  type    = string
  default = "on"
}

variable "disk_size" {
  type    = number
  default = 10
}
variable "disk_ssd" {
  type    = bool
  default = true
}

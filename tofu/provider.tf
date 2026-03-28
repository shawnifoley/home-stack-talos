terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.99"
    }
  }
}

provider "proxmox" {
  endpoint = "https://${var.pm_host}"
  username = var.pm_user
  password = var.pm_api_password
  insecure = var.pm_tls_insecure
}

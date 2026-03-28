locals {
  num_controlplane_vms = length(var.controlplane_ips)
  num_worker_vms       = length(var.worker_ips)
  vm_name_prefix       = var.deployment_name == "prod" ? "" : "${var.deployment_name}-"
}

resource "proxmox_virtual_environment_vm" "proxmox_vm_controlplane" {
  count     = local.num_controlplane_vms
  name      = "${local.vm_name_prefix}talos-cp${count.index + 1}"
  node_name = var.pm_node_name
  pool_id   = var.pool_id
  tags      = var.tags

  clone {
    vm_id = var.template_id
  }

  agent {
    enabled = true
    wait_for_ip {
      ipv4 = true
    }
  }
  cpu {
    cores = var.cpu_cores
    type  = var.cpu_type
  }
  memory {
    dedicated = var.num_controlplane_mem
  }
  disk {
    datastore_id = var.datastore
    interface    = var.disk_interface
    discard      = var.disk_discard
    size         = var.disk_size
    ssd          = var.disk_ssd
  }
  network_device {
    bridge      = var.net_bridge
    mac_address = length(var.controlplane_macs) > 0 ? var.controlplane_macs[count.index] : null
  }
}

resource "proxmox_virtual_environment_vm" "proxmox_vm_workers" {
  count     = local.num_worker_vms
  name      = "${var.deployment_name}-talos-worker${count.index + 1}"
  node_name = var.pm_node_name
  pool_id   = var.pool_id
  tags      = var.tags

  clone {
    vm_id = var.template_id
  }

  agent {
    enabled = true
    wait_for_ip {
      ipv4 = true
    }
  }
  cpu {
    cores = var.cpu_cores
    type  = var.cpu_type
  }
  memory {
    dedicated = var.num_worker_mem
  }
  disk {
    datastore_id = var.datastore
    interface    = var.disk_interface
    discard      = var.disk_discard
    size         = var.disk_size
    ssd          = var.disk_ssd
  }
  network_device {
    bridge      = var.net_bridge
    mac_address = length(var.worker_macs) > 0 ? var.worker_macs[count.index] : null
  }
}

resource "local_file" "k8s_file" {
  content = templatefile("./templates/k8s.tpl", {
    k3s_master_nodes = [
      for idx, instance in proxmox_virtual_environment_vm.proxmox_vm_controlplane : {
        name      = instance.name
        static_ip = var.controlplane_ips[idx]
        dhcp_ip = try(
          [
            for ip in flatten(instance.ipv4_addresses) : ip
            if ip != "" && !startswith(ip, "127.") && !startswith(ip, "169.254.")
          ][0],
          null
        )
      }
    ]
    k3s_worker_nodes = [
      for idx, instance in proxmox_virtual_environment_vm.proxmox_vm_workers : {
        name      = instance.name
        static_ip = var.worker_ips[idx]
        dhcp_ip = try(
          [
            for ip in flatten(instance.ipv4_addresses) : ip
            if ip != "" && !startswith(ip, "127.") && !startswith(ip, "169.254.")
          ][0],
          null
        )
      }
    ]
  })
  filename = "../ansible/inventory/${var.deployment_name}/hosts.ini"
}

resource "local_file" "talos_dhcp_snapshot" {
  content = jsonencode({
    deployment = var.deployment_name
    controlplane = [
      for idx, instance in proxmox_virtual_environment_vm.proxmox_vm_controlplane : {
        name      = instance.name
        static_ip = var.controlplane_ips[idx]
        mac       = length(var.controlplane_macs) > 0 ? var.controlplane_macs[idx] : null
        dhcp_ip = try(
          [
            for ip in flatten(instance.ipv4_addresses) : ip
            if ip != "" && !startswith(ip, "127.") && !startswith(ip, "169.254.")
          ][0],
          null
        )
      }
    ]
    workers = [
      for idx, instance in proxmox_virtual_environment_vm.proxmox_vm_workers : {
        name      = instance.name
        static_ip = var.worker_ips[idx]
        mac       = length(var.worker_macs) > 0 ? var.worker_macs[idx] : null
        dhcp_ip = try(
          [
            for ip in flatten(instance.ipv4_addresses) : ip
            if ip != "" && !startswith(ip, "127.") && !startswith(ip, "169.254.")
          ][0],
          null
        )
      }
    ]
  })
  filename = "../ansible/inventory/${var.deployment_name}/dhcp.json"
}

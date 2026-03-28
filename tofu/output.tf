output "controlplane_ips" {
  value = var.controlplane_ips
}

output "worker_ips" {
  value = var.worker_ips
}

output "controlplane_dhcp_ips" {
  value = [
    for instance in proxmox_virtual_environment_vm.proxmox_vm_controlplane :
    try(
      [
        for ip in flatten(instance.ipv4_addresses) : ip
        if ip != "" && !startswith(ip, "127.") && !startswith(ip, "169.254.")
      ][0],
      null
    )
  ]
}

output "worker_dhcp_ips" {
  value = [
    for instance in proxmox_virtual_environment_vm.proxmox_vm_workers :
    try(
      [
        for ip in flatten(instance.ipv4_addresses) : ip
        if ip != "" && !startswith(ip, "127.") && !startswith(ip, "169.254.")
      ][0],
      null
    )
  ]
}


[masters]
%{ for master in k8s_master_nodes ~}
${master.name} ansible_host=${coalesce(master.dhcp_ip, master.static_ip)} talos_dhcp_ip=${coalesce(master.dhcp_ip, master.static_ip)} talos_static_ip=${master.static_ip} talos_hostname=${master.name}
%{ endfor ~}

[workers]
%{ for worker in k8s_worker_nodes ~}
${worker.name} ansible_host=${coalesce(worker.dhcp_ip, worker.static_ip)} talos_dhcp_ip=${coalesce(worker.dhcp_ip, worker.static_ip)} talos_static_ip=${worker.static_ip} talos_hostname=${worker.name}
%{ endfor ~}

[talos_cluster:children]
masters
workers

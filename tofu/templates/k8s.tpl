[masters]
%{ for master in k3s_master_nodes ~}
${master.name} ansible_host=${coalesce(master.dhcp_ip, master.static_ip)} talos_dhcp_ip=${coalesce(master.dhcp_ip, master.static_ip)} talos_static_ip=${master.static_ip} talos_hostname=${master.name}
%{ endfor ~}

[controlplane:children]
masters

[workers]
%{ for worker in k3s_worker_nodes ~}
${worker.name} ansible_host=${coalesce(worker.dhcp_ip, worker.static_ip)} talos_dhcp_ip=${coalesce(worker.dhcp_ip, worker.static_ip)} talos_static_ip=${worker.static_ip} talos_hostname=${worker.name}
%{ endfor ~}

[talos_cluster:children]
masters
workers

[k3s_cluster:children]
masters
workers

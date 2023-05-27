[${group_name}]
%{ for ansible_host in ans_hosts ~}
${ansible_host.name} ansible_host='${ansible_host.network[0].ip} '
%{ endfor ~}

[${group_name}:vars]
${group_name}:vars]
#force_ansible_run ${force_ansible_run}
ansible_user=${ansible_user}

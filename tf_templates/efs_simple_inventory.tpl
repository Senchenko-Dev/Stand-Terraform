[${group_name}]
%{ for ansible_host in ans_hosts ~}
${ansible_host.name} ansible_host='${ansible_host.ip}'
%{ endfor ~}


[wildfly:children]
${group_name}

[${group_name}]
%{ for ansible_host in vm_instances ~}
${ansible_host.name} ansible_host='${ansible_host.network[0].ip}' out_wf_version='${ansible_host.metadata.wildfly_version}'
%{ endfor ~}

[${group_name}:vars]
#force_ansible_run ${force_ansible_run}
ansible_user=${ansible_user}

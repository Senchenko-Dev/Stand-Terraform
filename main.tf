
locals {
  stand_name = "Bystrov" # TODO Имя стенда
  network_name = "main_VDC02"
  vault_file = "secrets.yml" # todo внимание, хардкод в Jenkinsfile!
  # Для setup_vm. Публичные ключи для входа на хосты.
  ssh_keys_list = [
    { username = "senchenko", ssh_key = local.secrets.ssh.sentsov, sudo = true},
    { username = "root", ssh_key = local.secrets.ssh.root},
  ]
  # параметры для VCD_VM
  vm_props_default = {
    #-------------CentOs-8.4----------------#
#    template_name = "SBT-SPO-RHEL84-latest"
#    catalog_name = "SBT_CREATOR_TEMPLATES"
    #---------------------------------------#
    template_name = "SBT-SPO-RHEL79-latest"
    catalog_name = "RHEL7"
    #---------CentOs7-----------#
#    template_name = "CentOS7_64-bit"
#    catalog_name = "Linux Templates"

    network_type = "org"
    ip_allocation_mode = "POOL"

    network_name = local.network_name
    stand_name = local.stand_name

    ssh_keys_list = local.ssh_keys_list
    guest_properties = local.guest_properties_common
    private_key = local.secrets.ssh.key_rsa
    public_key = local.secrets.ssh.key_pub
  }
  # дополнительные параметры для кастомизированного образа
  guest_properties_common = {
    "enablecustomization" : "enabled",
    "rootpassword" : local.secrets.guest_properties_common.rootpassword,
    "dnsserver" : "10.255.1.3",
    "ansible_auth_pub_key" : local.secrets.ssh.key_pub # ключ пользователя ansible
  }
}

# AWX
locals {
  install_awx_props = {
    awx_port = 30800
    pod_nginx_port = 30900
    vault_file = local.vault_file
    scm_cred_name = "${local.stand_name} SCM Credential"
    scm_username = var.scm_username
    scm_password = var.scm_password
    machine_cred_username = "ansible"

    stand_admin_username = "${local.stand_name}-admin"

    stand_admin_email = "{{ '' | default('email@default.com', true) }}"
    org_name = local.stand_name
    scm_url = var.scm_url
    scm_branch = var.scm_branch
  }
}

module "AWX" {
   count = 0
   vm_count = 0
  # TF path to the module
  source = "./modules/awx"
  # VM settings
  //  cpu = 6
  //  memory = 12288
  # VM properties
  vm_props = local.vm_props_default
  # Ansible properties
  inventory_group_name = "awx-group" // для связи с group_vars/group_name.yml
  awx_props = local.install_awx_props
  vault_file = local.vault_file
}

locals {
  //  awx_props = local.external_awx_props  #  При использовании внешнего AWX прописать хост и урл в явном виде.
  awx_props = merge(local.install_awx_props,
#    {
#      awx_host = module.AWX.awx_host_ip
#      awx_url = "http://${module.AWX.awx_host_ip}:${local.install_awx_props.awx_port}"
#      awx_k8s_sa_name = local.globals.devopsSaName
#      awx_k8s_sa_project = local.globals.devopsProject
#    }
  )
}

# NGINX
module "NginxG1" {
  source = "./modules/spo_nginx"
  # VM properties
  count = 0

  vm_count = 1
  cpu = 1
  memory = 512
  vm_disk_data = [
    //  { size: "3G", mnt_dir: "/opt/nginx" , owner: "nginx"},
    //   { size: "1G", mnt_dir: "/var/log/nginx" , owner: "nginx", group: "nginx", mode: "0755"}
  ]
  vm_props = local.vm_props_default
  awx_props = local.awx_props

  # Ansible properties
  force_ansible_run = "0"
  inventory_group_name = "nginx_ssl" // для связи с group_vars/group_name.yml
  spo_role_name = "nginx"
  vault_file = local.vault_file
}


module "KAFKA_Corex_standalone" {
  count = 0

  vm_count = 1
  # TF module properties
  source = "./modules/kafka_corex"

  # Ansible properties
  inventory_group_name = "kafka-corex"
  force_ansible_run = ""
  #000_${timestamp()}" #  "_${timestamp()}"

  kafka_url = "http://10.42.4.125/mirror/docker/images/kafka/KFK-6.zip"

  # VM properties
  memory = 4024 #16*1024
  cpu = 4
  #   vm_disk_data = [
  #     { size: "350G", mnt_dir: "/KAFKA" , owner: "kafka", group: "kafka", mode: "0755"}
  #   ]

  vm_props = local.vm_props_default
  vault_file = local.vault_file
  spo_role_name = "kafka" # На самом деле эта роль KAFKA COREX из за зависимости от имени роли пришлось оставить по умолчанию kafka
  awx_props = local.awx_props

}


module "ELK_standalone1" {

  count = 0

  vm_count = 1
  # TF module properties
  source = "./modules/elk"

  # Ansible properties
  inventory_group_name = "ELK1"
  force_ansible_run = ""

  # VM properties
  memory = 6 * 1024 #16*1024
  cpu = 6

  vm_disk_data = [
    { size: "40G", mnt_dir: "/opt/elastic" , owner: "nginx"},
  ]

  vm_props = local.vm_props_default
  vault_file = local.vault_file
  spo_role_name = "elk"
  awx_props = local.awx_props

}

#123
# PG
module "PGSE_standalone01" {
  count = 1

  source = "./modules/spo_pangolin"
  # VM properties
  vm_props = local.vm_props_default
  # для postgres nodes:
  cpu = 2
  memory = 4*1024
  vm_pg_disk_data = [
    //        { size : "20G", mnt_dir : "/pgdata" },
  ]
  # Ansible properties
  inventory_group_name = "Pangolin_alone-1"
  vault_file = local.vault_file
  force_ansible_run = "master"

  # Download
  pangolin_url = "https://dzo.sw.sbc.space/nexus-cd/repository/sbt_PROD/sbt_PROD/CI90000013_pangolin/D-04.006.00-010/CI90000013_pangolin-D-04.006.00-010-distrib.tar.gz"

  # Install
  installation_type = "standalone"
  installation_subtype = "standalone-postgresql-only"
}
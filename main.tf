#0
locals {


  stand_name = "inner-bf1" # TODO Имя стенда
  network_name = "main_VDC02"
  vault_file = "secrets.yml" # todo внимание, хардкод в Jenkinsfile!
  # Для setup_vm. Публичные ключи для входа на хосты.
  ssh_keys_list = [
    { username: "user", ssh_key: local.secrets.ssh.user},
    { username: "provuser", ssh_key: local.secrets.ssh.provuser, sudo: true},
    { username: "sentsov", ssh_key: local.secrets.ssh.sentsov, sudo: true},
    { username: "root", ssh_key: local.secrets.ssh.root},
  ]
  # параметры для VCD_VM
  vm_props_default = {
    template_name = "CentOS7_64-bit_custom2"
    catalog_name = "Custom"
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
  # TF path to the module
  source = "./modules/awx"
  # VM settings
  vm_count = 1
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
  awx_props = {}  #  При использовании внешнего AWX прописать хост и урл в явном виде.
/*
  awx_props = merge(local.install_awx_props,
    { #  При использовании внешнего AWX прописать хост и урл в явном виде.
      awx_host = module.AWX.awx_host_ip
      awx_url = "http://${module.AWX.awx_host_ip}:${local.install_awx_props.awx_port}"
      awx_k8s_sa_name = local.globals.devopsSaName
      awx_k8s_sa_project = local.globals.devopsProject
    }
  )
  */
}

 module "PGSE_standalone" {
//   count = 0
   # TF module properties
   source = "./modules/spo_pangolin"

   # Ansible properties
   inventory_group_name = "pangolin_cfga" # заполнить group_vars
   force_ansible_run = "1"

   # Download and unpack
   pangolin_url = "https://dzo.sw.sbc.space/nexus-cd/repository/sbt_PROD/sbt_PROD/CI90000013_pangolin/D-04.006.00-010/CI90000013_pangolin-D-04.006.00-010-distrib.tar.gz"
   unpack_exclude = ["installer"]
   # Install
   installation_type = "standalone"
   installation_subtype = "standalone-postgresql-only"
   # VM properties
   # только для postgres nodes
   cpu = 2
   memory = 3048 #8*1024
   vm_pg_disk_data = [
     { size : "200G", mnt_dir : "/pgdata" },  # только для postgres nodes
   ]

 //  vm_etcd_disk_data = [
 //    { size : "2G", mnt_dir : local.pgdata_dir },  # только для postgres nodes
 //  ]

   vm_props = local.vm_props_default
   vault_file = local.vault_file
 }
#
 module "PGSE_standalone_test" {
//   count = 0
   # TF module properties
   source = "./modules/spo_pangolin"

   # Ansible properties
   inventory_group_name = "pangolin_test" # заполнить group_vars
   force_ansible_run = "0"

   # Download and unpack
   pangolin_url = "https://dzo.sw.sbc.space/nexus-cd/repository/sbt_PROD/sbt_PROD/CI90000013_pangolin/D-04.006.00-010/CI90000013_pangolin-D-04.006.00-010-distrib.tar.gz"
   unpack_exclude = ["installer"]
   # Install
   installation_type = "standalone"
   installation_subtype = "standalone-postgresql-only"
   # VM properties
   # только для postgres nodes
   cpu = 2
   memory = 3048 #8*1024
   vm_pg_disk_data = [
     { size : "200G", mnt_dir : "/pgdata" },  # только для postgres nodes
   ]

 //  vm_etcd_disk_data = [
 //    { size : "2G", mnt_dir : local.pgdata_dir },  # только для postgres nodes
 //  ]

   vm_props = local.vm_props_default
   vault_file = local.vault_file
 }
#
module "CORAX_Kafka1" {
  count = 0
  source = "./modules/spo_kafka_se"

  kafka_url = "https://dzo.sw.sbc.space/nexus-cd/repository/sbt_PROD/sbt_PROD/CI90000065_kfka/KFK/6.272.0-11/KFK-6.272.0-11-distrib.zip"

  inventory_group_name = "global_kafka"
  vm_count = 1
  memory = 12*1024
  cpu = 8
  vm_props = local.vm_props_default
  vault_file = local.vault_file
//  spo_role_name = "corax"
}

module "Kafka303" {
//  count = 0

  # TF module properties
  source = "./modules/spo_kafka_se"

  # Ansible properties
  inventory_group_name = "Kafka1"
  force_ansible_run = ""

  kafka_url = "https://dzo.sw.sbc.space/nexus-cd/repository/sbt_nexus_prod/Nexus_PROD/CI02556575_KAFKA_SE/3.0.3/CI02556575_KAFKA_SE-3.0.3-distrib.zip"

  # VM properties
  vm_count = 1
  memory = 8*1024
  cpu = 4
  vm_disk_data = [
    {size: "35G", mnt_dir: "/KAFKA", owner: "kafka", group: "kafka", mode: "0755"}
  ]

  vm_props = local.vm_props_default
  vault_file = local.vault_file
}

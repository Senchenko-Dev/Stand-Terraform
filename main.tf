#0123
locals {
#12s
  stand_name = "senchenko-test"
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
    awx_login = "admin"
    awx_password = local.secrets.awx.awx_password
    scm_cred_name = "${local.stand_name} SCM Credential"
    scm_username = var.scm_username
    scm_password = var.scm_password
    machine_cred_name = "${local.stand_name} Machine Credential"
    machine_cred_username = "ansible"
    machine_cred_ssh_key_data = local.secrets.awx.machine_cred_ssh_key_data

    stand_admin_username = "${local.stand_name}-admin"
    stand_admin_password = local.secrets.awx.stand_admin_password

    stand_admin_email = "{{ '' | default('email@default.com', true) }}"
    org_name = local.stand_name
    scm_url = var.scm_url
    scm_branch = var.scm_branch
  }

  external_awx_props = {
    awx_host = "10.42.4.123"
    awx_url = "http://10.42.4.123:30980/#/organizations"
    pod_nginx_port = 30900


    awx_login = "admin"
    awx_password = local.secrets.awx.awx_password
    scm_cred_name = "${local.stand_name} SCM Credential"
    scm_username = var.scm_username
    scm_password = var.scm_password
    machine_cred_name = "${local.stand_name} Machine Credential"
    machine_cred_username = "ansible"
    machine_cred_ssh_key_data = local.secrets.awx.machine_cred_ssh_key_data

    stand_admin_username = "${local.stand_name}-admin"
    stand_admin_password = local.secrets.awx.stand_admin_password

    stand_admin_email = "{{ '' | default('email@default.com', true) }}"
    org_name = local.stand_name
    scm_url = var.scm_url
    scm_branch = var.scm_branch
  }
}

module "AWX" {
  //count = 0
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
//  awx_props = local.external_awx_props  #  При использовании внешнего AWX прописать хост и урл в явном виде.
///*
  awx_props = {}
/*  merge(local.install_awx_props,
    { #  При использовании внешнего AWX прописать хост и урл в явном виде.
      awx_host = module.AWX.awx_host_ip
      awx_url = "http://${module.AWX.awx_host_ip}:${local.install_awx_props.awx_port}"
      awx_k8s_sa_name = local.globals.devopsSaName
      awx_k8s_sa_project = local.globals.devopsProject
    }
  )
//*/
}

# NGINX
module "NginxG1" {
  source = "./modules/spo_nginx"

  count = 0
# VM properties
  cpu = 1
  memory = 512
  vm_count = 0
  vm_props = local.vm_props_default
  vm_disk_data = [
 //  { size: "3G", mnt_dir: "/opt/nginx" , owner: "nginx"},
//   { size: "1G", mnt_dir: "/var/log/nginx" , owner: "nginx", group: "nginx", mode: "0755"}
  ]

# Ansible properties
  inventory_group_name = "nginx_http" // для связи с group_vars/group_name.yml
  awx_props = local.awx_props
  vault_file = local.vault_file
}



/*
# NGINX_IAG
module "Nginx_IAG" {
  source = "./modules/spo_nginx_iag"

  ## VM properties
  vm_props = local.vm_props_default

  # Ansible properties
  nginx_iag_url = "https://dzo.sw.sbc.space/nexus-cd/repository/sbt_nexus_prod/Nexus_PROD/CI01536898_APIGATE/D-02.020.00-1390_iag_release_19_4_rhel7.x86_64/CI01536898_APIGATE-D-02.020.00-1390_iag_release_19_4_rhel7.x86_64-distrib.zip"
  inventory_group_name = "nginx_iag" // для связи с group_vars/group_name.yml
  vault_file = local.vault_file
}



# NGINX_SGW
module "Nginx_SGW" {
  source = "./modules/spo_nginx_sgw"

  vm_count = 0

  ## VM properties
  vm_props = local.vm_props_default

  # Ansible properties
  nginx_sgw_url = "https://dzo.sw.sbc.space/nexus-cd/repository/sbt_PROD/sbt_PROD/CI90000178_sgwx/D-02.021.03-11_release_19_5_1_sgw_nginx_1_20_1_dzo_rhel7.x86_64/CI90000178_sgwx-D-02.021.03-11_release_19_5_1_sgw_nginx_1_20_1_dzo_rhel7.x86_64-distrib.zip"
  inventory_group_name = "nginx_sgw" // для связи с group_vars/group_name.yml
  vault_file = local.vault_file
}
*/
































/*
# KAFKA
module "KAFKA1" {
   count = 0
   source = "./modules/spo_kafka_se"
   # VM properties
   cpu = 2
   memory = 1024*3
   vm_count = 1
   vm_props = local.vm_props_default
   vm_disk_data = [
//     { size: "50G", mnt_dir: "/KAFKA" , owner: "kafka", group: "kafka", mode: "0755"}
   ]
   # Ansible properties
   inventory_group_name = "Kafka1"
   vault_file = local.vault_file

   # Download
    kafka_url = "https://dzo.sw.sbc.space/nexus-cd/repository/sbt_nexus_prod/Nexus_PROD/CI02556575_KAFKA_SE/3.0.3/CI02556575_KAFKA_SE-3.0.3-distrib.zip"
 }

# PG
module "PGSE_standalone01" {
  count = 0
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
//*/
locals {

  stand_name = "silim-premerge" # TODO Имя стенда
  network_name = "main_VDC02"

  vault_file = "secrets.yml"

# передается в модуль (затем в провайдер VCD_VM)
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

# Для setup_vm
  ssh_keys_list = [
    { username: "user", ssh_key: local.secrets.ssh.user},
    { username: "provuser", ssh_key: local.secrets.ssh.provuser, sudo: true},
    { username: "sentsov", ssh_key: local.secrets.ssh.sentsov, sudo: true},
    { username: "root", ssh_key: local.secrets.ssh.root},
  ]
}

# AWX
locals {
  install_awx_props = {
    awx_port = 30800
    pod_nginx_port = 30900
    vault_file = local.vault_file
#    awx_login = local.secrets.awx.awx_login # "admin"
#    awx_password = local.secrets.awx.awx_password
    scm_cred_name = "${local.stand_name} SCM Credential"
    scm_username = var.scm_username
    scm_password = var.scm_password
#    machine_cred_name = "${local.stand_name} Machine Credential"
    machine_cred_username = "ansible"
#    machine_cred_ssh_key_data = local.secrets.awx.machine_cred_ssh_key_data

    stand_admin_username = "${local.stand_name}-admin"
#    stand_admin_password = local.secrets.awx.stand_admin_password

    stand_admin_email = "{{ '' | default('email@default.com', true) }}"
    org_name = local.stand_name
    scm_url = var.scm_url
    scm_branch = var.scm_branch
  }
}

module "AWX" {
//  count = 0
  # TF path to the module
  source = "./modules/awx"

  # VM settings
  cpu = 6
  memory = 12288

  # VM hard disk settings

  # VM properties
  vm_props = local.vm_props_default

  # Ansible properties
  force_ansible_run = "000"

  awx_props = local.install_awx_props
  vault_file = local.vault_file
  inventory_group_name = "awx-group" // для связи с group_vars/group_name.yml
}

locals {
//  awx_props = local.external_awx_props  #  При использовании внешнего AWX прописать хост и урл в явном виде.
///*
  awx_props = merge(local.install_awx_props,
    { #  При использовании внешнего AWX прописать хост и урл в явном виде.
      awx_host = module.AWX.awx_host_ip
      awx_url = "http://${module.AWX.awx_host_ip}:${local.install_awx_props.awx_port}"
      awx_k8s_sa_name = local.globals.devopsSaName
      awx_k8s_sa_project = local.globals.devopsProject
    }
  )
}


# NGINX
module "NginxG1" {
  source = "./modules/spo_nginx"
# VM properties
  vm_count = 0
  memory = 512
  cpu = 1
  vm_disk_data = [
//   { size: "3G", mnt_dir: "/opt/nginx" , owner: "nginx"},
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

module "Nginx_iag" {
  source = "./modules/spo_nginx_iag"
  count = 0
  ## VM properties
  vm_props = local.vm_props_default

  # Ansible properties
  nginx_iag_url = "https://dzo.sw.sbc.space/nexus-cd/repository/sbt_nexus_prod/Nexus_PROD/CI01536898_APIGATE/D-02.020.00-1390_iag_release_19_4_rhel7.x86_64/CI01536898_APIGATE-D-02.020.00-1390_iag_release_19_4_rhel7.x86_64-distrib.zip"
  inventory_group_name = "nginx_iag" // для связи с group_vars/group_name.yml
  vault_file = local.vault_file
}


 module "KAFKA_standalone1" {
   # depends_on = [module.AWX]
   count = 1
   # TF module properties
   source = "./modules/kafka_corex"

   # Ansible properties
   inventory_group_name = "kafka-corex"
 //  spo_role_name = ""
   force_ansible_run = ""
   #000_${timestamp()}" #  "_${timestamp()}"

   # Download
 //  nexus_cred = {
 //    nexususer = local.secrets.nexususer,
 //    nexuspass = local.secrets.nexuspass,
 //  }
   kafka_url = "http://10.42.4.125/mirror/docker/images/kafka/KFK-6.zip"

   # VM properties
   vm_count = 3
   memory = 4024 #16*1024
   cpu = 4
#   vm_disk_data = [
#     { size: "350G", mnt_dir: "/KAFKA" , owner: "kafka", group: "kafka", mode: "0755"}
#   ]

   vm_props = local.vm_props_default
   vault_file = local.vault_file
   spo_role_name = "kafka"
   awx_props = local.awx_props

 }

 module "KAFKA_SSL1" {
   count = 0
   # TF module properties
   source = "./modules/spo_kafka_se"

   # Ansible properties
   inventory_group_name = "KafkaSSL"
 //  spo_role_name = ""
   force_ansible_run = ""
   #000_${timestamp()}" #  "_${timestamp()}"

   # Download
   # kafka_url = "https://dzo.sw.sbc.space/nexus-cd/repository/sbt_nexus_prod/Nexus_PROD/CI02556575_KAFKA_SE/3.0.3/CI02556575_KAFKA_SE-3.0.3-distrib.zip"

   # VM properties
   vm_count = 0
   memory = 2*1024
   cpu = 2
   vm_disk_data = [
 //    { size: "350G", mnt_dir: "/KAFKA" , owner: "kafka", group: "kafka", mode: "0755"}
   ]
   vault_file = local.vault_file
   vm_props = local.vm_props_default
 }


 module "PGSE_standalone" {
   count = 0
   # TF module properties
   depends_on = []
   source = "./modules/spo_pangolin"

   # Ansible properties
   inventory_group_name = "Pangolin_alone-1"
   force_ansible_run = "000" #  "_${timestamp()}"

   # Download
   pangolin_url = "https://dzo.sw.sbc.space/nexus-cd/repository/sbt_PROD/sbt_PROD/CI90000013_pangolin/D-04.006.00-010/CI90000013_pangolin-D-04.006.00-010-distrib.tar.gz"

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

/*
module "PGSE_cluster" {
  # TF module properties
  source = "./modules/pangolin"

  # Ansible properties
  inventory_group_name = "Pangolin-cluster-1"
  force_ansible_run = ""

  # Download
  nexus_cred = {
    nexususer = var.nexususer,
    nexuspass = var.nexuspass,
  }
  pangolin_url = local.pangolin460-010_url// TODO перенести в файл настроек

  # Install
  installation_type = local.pangolin_installation_type.cluster
  installation_subtype = local.pangolin_installation_subtype.cluster-patroni-etcd-pgbouncer

  # VM properties
  # только для postgres nodes
  vm_pg_disk_data = [
    { size : "10G", mnt_dir : local.pgdata_dir },
  ]
  vm_etcd_disk_data = [
    { size : "2G", mnt_dir : local.pgdata_dir },
  ]
  vm_props = local.vm_props_default
}
*/

module "ELK_standalone1" {


  count = 0
  # TF module properties
  source = "./modules/elk"

  # Ansible properties
  inventory_group_name = "ELK1"
  force_ansible_run = ""

  # VM properties
  vm_count = 1
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
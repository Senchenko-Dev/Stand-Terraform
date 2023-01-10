terraform {
  required_providers {
    vcd = {
      source = "vmware/vcd"
    }
  }
  required_version = ">= 0.13"
}

locals {
  vm_list_standalone = ["master"]
  vm_list_cluster = ["master","replica","etcd"]
  vm_list_cluster_postgres_nodes = ["master","replica"]
  vm_list_cluster_etcd_nodes = ["etcd"]

  postgres_nodes = var.installation_type == "standalone" ? local.vm_list_standalone : var.installation_type == "cluster" ? local.vm_list_cluster_postgres_nodes : []
  etcd_nodes = var.installation_type == "cluster" ? local.vm_list_cluster_etcd_nodes : []
}

locals {
  final_pg_disks_data = flatten([
    for vm_suffix in local.postgres_nodes : [
      for disk in var.vm_pg_disk_data : {
        "${var.vm_props.stand_name}-${var.inventory_group_name}-vm_${vm_suffix}-disk-${index(var.vm_pg_disk_data, disk)}" = disk
      }
    ]
  ])
  final_etcd_disks_data = flatten([
    for vm_suffix in local.etcd_nodes : [
      for disk in var.vm_etcd_disk_data : {
        "${var.vm_props.stand_name}-${var.inventory_group_name}-vm_${vm_suffix}-disk-${index(var.vm_etcd_disk_data, disk)}" = disk
      }
    ]
  ])
}

resource "vcd_independent_disk" "pg_disks" {
  for_each = { for disk in local.final_pg_disks_data : keys(disk)[0] => values(disk)[0] }
  name         = each.key
  bus_type        = "SCSI"  
  bus_sub_type = "VirtualSCSI"
  size_in_mb      = trim(each.value.size, "G") * 1024
}

resource "vcd_independent_disk" "etcd_disks" {
  for_each = { for disk in local.final_etcd_disks_data : keys(disk)[0] => values(disk)[0] }
  name         = each.key
  bus_type        = "SCSI"  
  bus_sub_type = "VirtualSCSI"
  size_in_mb      = trim(each.value.size, "G") * 1024
}


#---------------------СОЗДАНИЕ VM--------------------+
resource "vcd_vm" "Pangolin-postgres" {

  depends_on = [vcd_independent_disk.pg_disks]

  for_each = toset(local.postgres_nodes)
  name = "${var.vm_props.stand_name}-${var.inventory_group_name}-vm_${each.value}"

  // параметры образа
  catalog_name = var.vm_props.catalog_name
  template_name = var.vm_props.template_name
  memory = var.memory
  cpus = var.cpu

  // сеть
  network {
    name = var.vm_props.network_name
    type = var.vm_props.network_type
    ip_allocation_mode = var.vm_props.ip_allocation_mode
  }

  // диски
  dynamic "disk" {
    for_each = { for disk_data in local.final_pg_disks_data: keys(disk_data)[0] => values(disk_data)[0] }
    content {
      name = "${var.vm_props.stand_name}-${var.inventory_group_name}-vm_${each.value}-disk-${index(var.vm_pg_disk_data, disk.value)}"
      bus_number = 0
      unit_number = "${index(var.vm_pg_disk_data, disk.value) + 1}"
    }
  }

  guest_properties = merge(
    var.vm_props.guest_properties,
    {
      "fqdn": "${var.vm_props.stand_name}-${var.inventory_group_name}-vm_${each.value}"
    }
  )

  // данные хранятся в клауде
  metadata = {
    host_alias: each.value,
    pangolin_version = var.pangolin_url,
  }
}

resource "vcd_vm" "Pangolin-etcd" {

  depends_on = [vcd_independent_disk.etcd_disks]

  for_each = toset(local.etcd_nodes)
  name = "${var.vm_props.stand_name}-${var.inventory_group_name}-etcd-${each.value}"

  // параметры образа
  catalog_name = var.vm_props.catalog_name
  template_name = var.vm_props.template_name
  memory = var.memory_etcd
  cpus = var.cpu_etcd

  // сеть
  network {
    name = var.vm_props.network_name
    type = var.vm_props.network_type
    ip_allocation_mode = var.vm_props.ip_allocation_mode
  }

  dynamic "disk" {
    for_each = { for disk_data in local.final_etcd_disks_data: keys(disk_data)[0] => values(disk_data)[0] }
    content {
      name = "${var.vm_props.stand_name}-${var.inventory_group_name}-vm_${each.value}-disk-${index(var.vm_etcd_disk_data, disk.value)}"
      bus_number = 0
      unit_number = "${index(var.vm_etcd_disk_data, disk.value) + 1}"
    }
  }

  guest_properties = merge(
    var.vm_props.guest_properties,
    {
      "fqdn": "${var.vm_props.stand_name}-${var.inventory_group_name}-vm_${each.value}"
    }
  )

  // данные хранятся в клауде
  metadata = {
    host_alias: each.value,
    pangolin_version = var.pangolin_url,
  }

}
#+---------------------------------------------------------+
// копирование груп варзов общих.
resource "null_resource" "copy_group_vars" {
  triggers = {
    always = timestamp(),
  }
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    //    command = "cp -rf ${abspath(path.root)}/inventory/group_vars ${abspath(path.root)}/inventory/"
    command = "cp -rf ${abspath(path.root)}/ansible/group_vars ${local.playbook_path}/"
  }

}

// создание инвентори для одной группы (модуля)
resource "local_file" "pangolin-inventory" {
  depends_on = [
    null_resource.copy_group_vars
//    vcd_vm.Pangolin-postgres,
//    vcd_vm.Pangolin-etcd
  ]

  filename = "ansible/inventory/${var.inventory_group_name}.ini"
  content = templatefile("tf_templates/pangolin/${var.installation_type}.hosts.ini", // todo optimize
//  content = templatefile("tf_templates/pangolin/pangolin.hosts.ini", // todo optimize
  {
    inventory_group_name = var.inventory_group_name
    vm_instances_postgres_nodes = vcd_vm.Pangolin-postgres,
    vm_instances_etcd_nodes     = vcd_vm.Pangolin-etcd
    ansible_user = "ansible"
    force_ansible_run: var.force_ansible_run

    pangolin_version: var.pangolin_url
    pangolin_url: var.pangolin_url

  })


  // параметры подключения для ансибла
  connection {
    user = "ansible"
    type = "ssh"
    private_key = var.vm_props.private_key
    host = ""
  }
  // запуск ансибла по инвентарю (на группу!)
  provisioner "ansible" {
    // Ожидание доступности хостов
    plays {
      playbook {
        file_path = "ansible/prepare_host_playbook.yml"
      }
      inventory_file = local_file.pangolin-inventory.filename
      extra_vars = {
        prepare_group: "postgres_nodes"
        ssh_keys_list: jsonencode(var.vm_props.ssh_keys_list),
        disks = jsonencode(var.vm_pg_disk_data)
      }
    }

    plays {
      playbook {
        file_path = "ansible/prepare_host_playbook.yml"
      }
      inventory_file = local_file.pangolin-inventory.filename
      extra_vars = {
        prepare_group: "etcd_nodes"
        ssh_keys_list: jsonencode(var.vm_props.ssh_keys_list),
        disks = jsonencode(var.vm_etcd_disk_data)
      }
    }

    // Настройка install-deps
    plays {
      playbook {
        file_path = "${local.playbook_path}/playbook_install_deps.yaml"
      }
      extra_vars = {}
      inventory_file = local_file.pangolin-inventory.filename
      become = true
    }
    // Скачивание дистрибутива СПО
    plays {
      playbook {
        file_path = "ansible/download_unpack.yml"
      }
      verbose = true
      extra_vars = {
        download_url: var.pangolin_url # filename
        download_dest: "${abspath(path.root)}/ansible/ext-pangolin/distr/${basename(var.pangolin_url)}" # filename
        unpack_dest: "${abspath(path.root)}/ansible/ext-pangolin/"
        //       unarchive:
        //        src: "{{ download_dest }}"
        //        dest: "{{ unpack_dest }}"
        vault_file: var.vault_file
      }
      vault_id = ["${abspath(path.root)}/ansible/login.sh"]
      inventory_file = local_file.pangolin-inventory.filename
    }
    // Установка СПО
    plays {
      playbook {
        file_path = "${abspath(path.root)}/ansible/pangolin.yml"
//        tags = []
        tags = ["always", var.installation_subtype]
      }
      inventory_file = local_file.pangolin-inventory.filename
      // переменные лучше подготовить файлом по шаблону
      extra_vars = {
        nolog = "false"
        action_type = "install"
        installation_type = var.installation_type
        tag = var.installation_subtype
        pangolin_version = var.pangolin_url
        custom_config = "${abspath(path.root)}/ansible/additional/pg_custom_config.yml"  # group_vars/custom_dev.yml # todo мне думается, лучше задавать в group_vars и сам файл располагать там же.
        manual_run = "yes"
        local_distr_path = "../"
        etcd_cluster_name = "${var.vm_props.stand_name}-${var.inventory_group_name}_etcd"
        clustername = "${var.vm_props.stand_name}-${var.inventory_group_name}"
        vault_file = var.vault_file
      }
      verbose = true
      vault_id = ["${abspath(path.root)}/ansible/login.sh"]
    }
    plays {
      playbook {
        file_path = "ansible/copy_bash_file.yaml"
      }
      inventory_file = local_file.pangolin-inventory.filename
      limit = "master"
    }

    ansible_ssh_settings {
      insecure_no_strict_host_key_checking = true
    }
  }
}

terraform {
  required_providers {
    vcd = {
      source = "vmware/vcd"
    }
  }
  required_version = ">= 0.13"
}

locals {
  final_disks_data = flatten([
    for vm_index in range(var.vm_count) : [
      for disk in var.vm_disk_data : {
        "${var.vm_props.stand_name}-${var.inventory_group_name}-vm_${vm_index}-disk-${index(var.vm_disk_data, disk)}" = disk
      }
    ]
  ])
}

resource "vcd_independent_disk" "disks" {
  for_each = { for disk in local.final_disks_data : keys(disk)[0] => values(disk)[0] }
  name         = each.key
  bus_type        = "SCSI"
  bus_sub_type = "VirtualSCSI"
  size_in_mb      = trim(each.value.size, "G") * 1024
}

#---------------------СОЗДАНИЕ VM--------------------+
resource "vcd_vm" "kafka" {

  depends_on = [vcd_independent_disk.disks]

  count = var.vm_count
  name = "${var.vm_props.stand_name}-${var.inventory_group_name}-vm_${count.index}"

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
    for_each = { for disk_data in local.final_disks_data: keys(disk_data)[0] => values(disk_data)[0] }
    content {
      name = "${var.vm_props.stand_name}-${var.inventory_group_name}-vm_${count.index}-disk-${index(var.vm_disk_data, disk.value)}"
      bus_number = 0
      unit_number = "${index(var.vm_disk_data, disk.value) + 1}"
    }
  }

  guest_properties = merge(
    var.vm_props.guest_properties,
    {
      "fqdn": "${var.vm_props.stand_name}-${var.inventory_group_name}-vm_${count.index}"
    }
  )

  // данные хранятся в клауде
  metadata = {
    host_alias: "kafka_${count.index}",
    kafka_version = var.kafka_url,
    KBrokerId = count.index
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
resource "local_file" "kafka-inventory" {
  depends_on = [null_resource.copy_group_vars]

  filename = "ansible/inventory/Kafka_${var.inventory_group_name}.ini"
  content = templatefile("tf_templates/kafka_se/hosts.ini", // todo optimize
  {
    vm_instances_kafka_nodes = vcd_vm.kafka,
    inventory_group_name = var.inventory_group_name
    ansible_user = "ansible"
    force_ansible_run: var.force_ansible_run
  })

  connection {
    user = "ansible"
    type = "ssh"
    private_key = var.vm_props.private_key
    host = ""
  }

  provisioner "ansible" {
    plays {
      playbook {
        file_path = "ansible/prepare_host_playbook.yml"
      }
      extra_vars = {
        ssh_keys_list: jsonencode(var.vm_props.ssh_keys_list)
        disks = jsonencode(var.vm_disk_data)
      }
      inventory_file = local_file.kafka-inventory.filename
    }

    // Настройка install-deps
    plays {
      playbook {
        file_path = "${local.playbook_path}/playbook_install_deps.yaml"
      }
      extra_vars = {
        vault_file: var.vault_file
      }
      inventory_file = local_file.kafka-inventory.filename
      become = true
      vault_id = ["${abspath(path.root)}/ansible/login.sh"]

    }

    // Скачивание дистрибутива СПО
    plays {
      playbook {
        file_path = "ansible/download_unpack.yml"
      }
      verbose = true
      extra_vars = {
        download_url: var.kafka_url
        download_dest: "${local.playbook_path}/roles/copy_distro_to_server/files/kafka.zip" # localhost!
        vault_file: var.vault_file
        //       nexusUser: var.nexus_cred.nexususer
//       nexusPass: var.nexus_cred.nexuspass
      }
      vault_id = ["${abspath(path.root)}/ansible/login.sh"]
      inventory_file = local_file.kafka-inventory.filename
    }

    // Установка СПО
    plays {
      playbook {
        file_path = "${local.playbook_path}/start_all_zk_and_kafka_systemd.yaml"
      }
      inventory_file = local_file.kafka-inventory.filename
      extra_vars = {}
      verbose = true
      groups = [
        var.inventory_group_name]
    }

    ###########################-test-#################################
    plays {
      playbook {
        file_path = "ansible/copy_bash_file.yaml"
      }
      extra_vars = {}
      inventory_file = local_file.kafka-inventory.filename
    }
    ###################################################################

    ansible_ssh_settings {
      insecure_no_strict_host_key_checking = true
    }
  }
}

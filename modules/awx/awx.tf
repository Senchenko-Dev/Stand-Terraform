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
        "${var.vm_props.stand_name}-${var.inventory_group_name}-vm-${vm_index}-disk-${index(var.vm_disk_data, disk)}" = disk
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
resource "vcd_vm" "VM-awx" {

  depends_on = [vcd_independent_disk.disks]

  count = var.vm_count
  name = "${var.vm_props.stand_name}-${var.inventory_group_name}-vm-${count.index}"

  // параметры образа
  catalog_name = var.vm_props.catalog_name
  template_name = var.vm_props.template_name
  memory = var.memory
  cpus = var.cpu

  #  network_dhcp_wait_seconds = 300
  network {
    name = var.vm_props.network_name
    type = var.vm_props.network_type
    ip_allocation_mode = var.vm_props.ip_allocation_mode
  }
  // диски
 
  dynamic "disk" {
    for_each = { for disk_data in local.final_disks_data : keys(disk_data)[0] => values(disk_data)[0] }
    content {
      name = "${var.vm_props.stand_name}-${var.inventory_group_name}-vm-${count.index}-disk-${index(var.vm_disk_data, disk.value)}"
      bus_number = 0
      unit_number = "${index(var.vm_disk_data, disk.value) + 1}"
    }
  }

#+---------------------------------------------------------+
  guest_properties = merge(
    var.vm_props.guest_properties,
    {
      "fqdn": "${var.vm_props.stand_name}-${var.inventory_group_name}-vm-${count.index}"
    }
  )

  metadata = {
    role = "AWX"
    env = "staging"
    version = "v1"
    my_key = "my value"
  }
}

// создание инвентори для одной группы (модуля)
resource "local_file" "awx-inventory" {
  # count = "${ var.vm_count != 0 ? 1 : 0 }"
  filename = "ansible/inventory/awx_${var.inventory_group_name}.ini"
  content  = templatefile("tf_templates/awx-inventory.tpl",
    {
      ans_hosts         = vcd_vm.VM-awx,
      ansible_user      = "ansible",
      group_name        = var.inventory_group_name
      force_ansible_run = var.force_ansible_run
    })


  // параметры подключения для ансибла
  connection {
    user        = "ansible"
    type        = "ssh"
    private_key = var.vm_props.private_key
    host        = ""
  }
  // запуск ансибла по инвентарю (на группу!)
  provisioner "ansible" {
    plays {
      playbook {
        file_path = "ansible/prepare_host_playbook.yml"
      }
      # inventory_file = local_file.awx-inventory[0].filename
      inventory_file = local_file.awx-inventory.filename
      extra_vars     = {
        ssh_keys_list : jsonencode(var.vm_props.ssh_keys_list)
        disks = jsonencode(var.vm_disk_data)
      }
    }
    // Установка СПО
    plays {
      playbook {
        file_path = "ansible/spo_install_playbook.yml"
      }
      inventory_file = local_file.awx-inventory.filename
      # inventory_file = local_file.awx-inventory[0].filename
      extra_vars     = {
        spo_role_name : var.spo_role_name
        vault_file : var.vault_file
        awx_port : var.awx_props.awx_port
        pod_nginx_port : var.awx_props.pod_nginx_port
        docker_registry_host: "10.42.4.125"
      }
      vault_id = ["${abspath(path.root)}/ansible/login.sh"]
    }

    // Подготовка стенда
    plays {
      playbook {
        file_path = "ansible/awx_config_all.yml"
        tags      = ["stand"]
      }
      hosts      = ["localhost"]
      extra_vars = merge({
        vault_file : var.vault_file
        spo_role_name : var.spo_role_name
      },
        var.awx_props,
        {
          awx_host : vcd_vm.VM-awx[0].network[0].ip
          awx_url : "http://${vcd_vm.VM-awx[0].network[0].ip}:${var.awx_props.awx_port}"
        }
      )
      vault_id = ["${abspath(path.root)}/ansible/login.sh"]
    }
    ansible_ssh_settings {
      insecure_no_strict_host_key_checking = true
    }
  }
}

// или только настройка стороннего AWX
resource "null_resource" "awx-config-stand" {
  count = "${ var.vm_count == 0 ? 1 : 0 }"
  // параметры подключения для ансибла
  connection {
    user        = "ansible"
    type        = "ssh"
    private_key = var.vm_props.private_key
    host        = ""
  }
    // Подготовка стенда
  provisioner "ansible" {
    plays {
      playbook {
        file_path = "ansible/awx_config_all.yml"
        tags = [
          "stand"]
      }
      hosts = [
        "localhost"]
      extra_vars = merge({
        vault_file : var.vault_file
        spo_role_name : var.spo_role_name
      },
      var.awx_props
      )
      vault_id = [
        "${abspath(path.root)}/ansible/login.sh"]
    }
    ansible_ssh_settings {
      insecure_no_strict_host_key_checking = true
    }
  }
}


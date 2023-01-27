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
resource "vcd_vm" "nginx_sgw" {

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
    nginx_sgw_version = var.nginx_sgw_url,
  }


}
#+---------------------------------------------------------+

// создание инвентори для одной группы (модуля)
resource "local_file" "nginx_sgw-inventory" {

  content    = templatefile("tf_templates/iag_inventory.tpl",
  {
    ans_hosts    = vcd_vm.nginx_sgw,
    ansible_user = "ansible",
    group_name = var.inventory_group_name
    force_ansible_run = var.force_ansible_run
  })
  filename = "ansible/inventory/${var.inventory_group_name}.ini"

  connection {
    user = "ansible"
    type = "ssh"
    private_key = var.vm_props.private_key
    host = ""
  }

  //подготовка стэнда
  provisioner "ansible" {
    plays {
      playbook {
        file_path = "ansible/prepare_host_playbook.yml"
      }
      extra_vars = {
        ssh_keys_list: jsonencode(var.vm_props.ssh_keys_list)
        disks = jsonencode(var.vm_disk_data)
      }
      inventory_file = local_file.nginx_sgw-inventory.filename
    }

    // Скачивание дистрибутива СПО
    plays {
      playbook {
        file_path = "ansible/download_unpack.yml"
      }
      verbose = true
      extra_vars = {
        download_url: var.nginx_sgw_url
        download_dest: "${abspath(path.root)}/ansible/roles/${var.spo_role_name}/files/" # localhost!
        vault_file: var.vault_file #"vault_secret.yml"
        //       nexusUser: var.nexus_cred.nexususer
        //       nexusPass: var.nexus_cred.nexuspass
      }
      vault_id = ["${abspath(path.root)}/ansible/login.sh"]
      inventory_file = local_file.nginx_sgw-inventory.filename
    }

    //Запуск роли СПО
    plays {
      playbook {
        file_path = "ansible/spo_install_playbook.yml"
      }
      extra_vars = {
        download_url: var.nginx_sgw_url
        spo_role_name: var.spo_role_name
        vault_file: var.vault_file 
      }
      vault_id = ["${abspath(path.root)}/ansible/login.sh"]
      inventory_file = local_file.nginx_sgw-inventory.filename
    }

    ansible_ssh_settings {
      insecure_no_strict_host_key_checking = true
    }
  }
}

/*
module "config_awx_ansible" {
  count = "${length(var.awx_props) != 0 ? 1 : 0}"
  source = "../awx_config_group"
  inventory_path = local_file.nginx-inventory.filename
  inventory_group_name = var.inventory_group_name
  spo_role_name = var.spo_role_name
  awx_props = var.awx_props
  vault_file = var.vault_file
  hosts = vcd_vm.VM-nginx
}
*/

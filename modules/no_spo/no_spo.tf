
terraform {
  required_providers {
    vcd = {
      source = "vmware/vcd"
    }
  }
  required_version = ">= 0.13"
}


#-------------УПРАВЛЕНИЕ КОЛИЧЕСТВОМ ДИСКОВ --------------+
module "Add_disks" {
  source = "../add_disk"
  for_each = toset(var.vm_vm_list)
  vapp_name = var.stand_name
  vm_name = "${var.stand_name}-${var.inventory_group_name}-${each.value}"
  disks = var.vm_disk_data

}
#+--------------------------------------------------------+

#---------------------СОЗДАНИЕ VM--------------------+
resource "vcd_vapp_vm" "VM-vm" {

  depends_on = [module.Add_disks]

  vapp_name = var.stand_name

  for_each = toset(var.vm_vm_list)
  name = "${var.stand_name}-${var.inventory_group_name}-${each.value}"

  catalog_name = var.catalog_name
  template_name = var.template_name
  memory = var.memory
  cpus = var.cpu

  #  network_dhcp_wait_seconds = 300
  network {
    name = var.network_name
    type = var.network_type
    ip_allocation_mode = var.ip_allocation_mode
  }

#+--------------new-block-independent-disk------------------+
  dynamic "disk" {
    for_each = var.vm_disk_data
    content {
      name = "${var.stand_name}-${var.inventory_group_name}-${each.value}-disk-${disk.value.id}"
      bus_number = 0
      unit_number = disk.value.id
    }
  }
#+---------------------------------------------------------+

  metadata = {
  }

  guest_properties = {
    "enablecustomization" : "enabled",
    "rootpassword" : "123qwe123",
    "fqdn" :  "${var.inventory_group_name}-${each.value}",
    "dnsserver" : "10.255.1.3",
    "ansible_auth_pub_key" : file("./key.pub")
  }
}

resource "time_sleep" "vm_started_timeout" {
  depends_on = [vcd_vapp_vm.VM-vm]

  create_duration = "1s"
  // must be 60 s
}

resource "local_file" "vm-inventory" {

  depends_on = [time_sleep.vm_started_timeout, module.Add_disks]

  content    = templatefile("tf_templates/vm_inventory.tpl",
  {
    ans_hosts    = vcd_vapp_vm.VM-vm,
    ansible_user = "ansible",
    group_name = var.inventory_group_name
    vm_files = jsonencode(var.overwrite_files_object.files)
    force_ansible_run = var.force_ansible_run
  })
  filename = "ansible/inventory/vm_${var.inventory_group_name}.ini"


  // параметры подключения для ансибла
  connection {
    user = "ansible"
    type = "ssh"
    private_key = file("./key.rsa")
    host = ""
  }
  // запуск ансибла по инвентарю (на группу!)
  provisioner "ansible" {
    // Ожидание доступности хостов
    plays {
      playbook {
        file_path = "ansible/wait_hosts.yml"
      }
      inventory_file = local_file.vm-inventory.filename
    }
    // Копирование ssh ключей
    plays {
      playbook {
        file_path = "ansible/copy_sshkeys.yml"
//        file_path = "ansible/provuser.yml"
      }
      extra_vars = {
        ssh_keys_list: jsonencode(var.ssh_keys_list)
      }
      inventory_file = local_file.vm-inventory.filename
      become = true
    }
    // Монтирование дисков
    plays {
      playbook {
        file_path = "ansible/mount-disk.yaml"
      }
      verbose = true
      extra_vars = {
        disks = jsonencode(var.vm_disk_data)
      }
      inventory_file = local_file.vm-inventory.filename
      become = true
    }
    // Установка репозиториев и прочая подготовка
    plays {
      playbook {
        file_path = "ansible/setup_vm.yml"
      }
      extra_vars = {}
      inventory_file = local_file.vm-inventory.filename
      become = true
    }
    
    ansible_ssh_settings {
      insecure_no_strict_host_key_checking = true
    }
  }

}
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



resource "vcd_vm" "VM-nginx" {

  depends_on = [vcd_independent_disk.disks]

  count = var.vm_count

  name = "${var.vm_props.stand_name}-${var.inventory_group_name}-vm_${count.index}"
  catalog_name = var.vm_props.catalog_name
  template_name = var.vm_props.template_name
  memory = var.memory
  cpus = var.cpu

  network {
    name = var.vm_props.network_name
    type = var.vm_props.network_type
    ip_allocation_mode = var.vm_props.ip_allocation_mode
  }
  // Кастомизация ОС
  customization {
    force                      = true        #Применить параметры кастомизации
    allow_local_admin_password = true        #Наличие локального пароля админа
    auto_generate_password     = false       #Отмена автогенерации пароля
    admin_password             = "123qwe123" #Пароль администратора
    initscript = <<EOF
                   #!/bin/sh
                   adduser ansible
                   echo "ansible  ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
                   mkdir -p /home/ansible/.ssh
                   echo "${var.vm_props.guest_properties.ansible_auth_pub_key}" >> /home/ansible/.ssh/authorized_keys
                   echo "${var.vm_props.stand_name}-${var.inventory_group_name}-vm_${count.index}" > /etc/hostname
                   sed -i "s/127\.0\.1\.1.*/127\.0\.1\.1  ${var.vm_props.stand_name}-${var.inventory_group_name}-vm_${count.index}/g" /etc/hosts
                   echo "nameserver ${var.vm_props.guest_properties.dnsserver}" > /etc/resolv.conf
                   EOF
  }

  dynamic "disk" {
    for_each = { for disk_data in local.final_disks_data : keys(disk_data)[0] => values(disk_data)[0] }
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

  metadata = {
    role = "Nginx"
    env = "staging"
    version = "v1"
    my_key = "my value"
  }
  

}

resource "local_file" "nginx-inventory" {
  content    = templatefile("tf_templates/nginx_inventory.tpl",
  {
    ans_hosts    = vcd_vm.VM-nginx,
    ansible_user = "ansible",
    group_name = var.inventory_group_name
    force_ansible_run = var.force_ansible_run
  })
  filename = "ansible/inventory/nginx_${var.inventory_group_name}.ini"

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
      inventory_file = local_file.nginx-inventory.filename
      extra_vars = {
        ssh_keys_list: jsonencode(var.vm_props.ssh_keys_list)
        disks = jsonencode(var.vm_disk_data)
      }
    }

    plays {
      playbook {
        file_path = "ansible/spo_install_playbook.yml"
      }
      inventory_file = local_file.nginx-inventory.filename
      extra_vars = {
        rolling_update_serial: "50%"
        spo_role_name: var.spo_role_name
        vault_file: var.vault_file
      }
      vault_id = ["${abspath(path.root)}/ansible/login.sh"]
    }

    ansible_ssh_settings {
      insecure_no_strict_host_key_checking = true
    }
  }
}

#resource "helm_release" "nginx" {
#  name        = "nginx"
#  chart       = "nginx"
#  repository  = "./charts"
#  namespace   = "tfstate-team-polyakov1"
#  max_history = 3
#  create_namespace = true
#  wait             = true
#  reset_values     = true
#}


# resource "helm_release" "test-charts" {
#   depends_on = [vcd_vm.VM-nginx]
#   name       = "my-local-chart"
#   chart      = "./charts/my-awsome-chart-0.1.0.tgz"
#   namespace   = "tfstate-team-polyakov1"
# }

#module "config_awx_ansible" {
#  count = "${length(var.awx_props) != 0 ? 1 : 0}"
#  source = "../awx_config_group"
#  inventory_path = local_file.nginx-inventory.filename
#  inventory_group_name = var.inventory_group_name
#  spo_role_name = var.spo_role_name
#  awx_props = var.awx_props
#  vault_file = var.vault_file
#  hosts = vcd_vm.VM-nginx
#}

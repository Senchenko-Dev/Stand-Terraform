terraform {
  required_providers {
    vcd = {
      source = "vmware/vcd"
    }
  }
  required_version = ">= 0.13"
}

resource "local_file" "wf_sys_props" {
  // todo как вариант - добавить папку custom_vars для использования include_vars
  filename = "${local.playbook_path}/vars/wf_sys_props.conf"
  content = file("wf_sys_props.conf")
}

resource "local_file" "files_for_overwrite" {
  count = length(var.overwrite_files_object.files)
  filename = "${local.playbook_path}/tf_templates/${basename(var.overwrite_files_object.files[count.index].src)}"
  content  = templatefile(
      var.overwrite_files_object.files[count.index].src,
      var.overwrite_files_object.args
  )
}


module "Add_disks" {
  source = "../add_disk"
  for_each = toset(var.vm_wildfly_list)
  vapp_name = var.stand_name
  vm_name = "${var.stand_name}-${var.inventory_group_name}-${each.value}"
  disks = var.vm_disk_data
}

#---------------------СОЗДАНИЕ VM--------------------+
resource "vcd_vapp_vm" "SPO_Terraform-Wildfly" {
  lifecycle {
    create_before_destroy = true
  }
  // виртуалки
    depends_on = [
      module.Add_disks,
//      null_resource.download_distrib_zip, // нет файла - нет выдачи.
    ]

  vapp_name = var.stand_name

  for_each = toset(var.vm_wildfly_list)
  // список позволяет удалять машины по алиасу
  name = "${var.stand_name}-${var.inventory_group_name}-${each.value}"

  // параметры образа
  catalog_name = var.catalog_name
  template_name = var.template_name
  memory = var.memory
  cpus = var.cpu
  guest_properties = merge(
  var.guest_properties_common,
  {
    "fqdn": "wildfly-${var.inventory_group_name}-${each.value}"
  }
  )

  // данные хранятся в клауде
  metadata = {
    wildfly_version = var.wildfly_url
  }

  // сеть
  network {
    name = var.network_name
    type = var.network_type     # "org"
    ip_allocation_mode = var.ip_allocation_mode     # "POOL"
  }
  // диски
  dynamic "disk" {
    for_each = var.vm_disk_data
    content {
      name = "${var.stand_name}-${var.inventory_group_name}-${each.value}-disk-${disk.value.id}"
      bus_number = 0
      unit_number = disk.value.id
    }
  }
//
//  provisioner "local-exec" {
//    #слип sleep
//    interpreter = ["bash", "-c"]
//    command = "sleep 60"
//  }

}
#+---------------------------------------------------------+

// задержка для запуска вм перед запуском общего ансибла
resource "time_sleep" "vm_started_timeout" {
  depends_on = [vcd_vapp_vm.SPO_Terraform-Wildfly]
  create_duration = "1s" // так не работает!!
  // must be 60 s
}

// создание group vars для одной группы (модуля)
resource "local_file" "WildFly-group_vars" {
  depends_on = [
    time_sleep.vm_started_timeout,
  ]
  filename = "ansible/inventory/group_vars/WildFly_${var.inventory_group_name}.yml" // TODO этот файл будет создаваться вручную администраторами.
  content = templatefile("tf_templates/wildfly_group_vars.tpl", // todo optimize
  {
    vm_instances = vcd_vapp_vm.SPO_Terraform-Wildfly,
    timestamp = timestamp()

//    overwrite_files: var.overwrite_files_object.files //

    wf_user: "fly" # var.wf_props.
    wfadminpass: "fly" # var.wf_props.
    wf_os_user: "wildfly" # var.wf_props.
    wf_os_user_pwd: "wildfly" # var.wf_props.
    wf_os_group: "wfgroup" # var.wf_props.
    wf_install_dir: var.wf_install_dir # var.wf_props.
    executed_by_terraform : "True"
    wildfly_url: var.wildfly_url # var.wf_props.
    PostgreSQL_jdbc_URL: var.postgresql_jdbc_url

  })
}
//│     │ var.wf_install_dir is a string, known only after apply
//│     │ var.wildfly_url will be known only after apply
//│     │ vcd_vapp_vm.SPO_Terraform-Wildfly will be known only after apply

// создание инвентори для одной группы (модуля)
resource "local_file" "WildFly-inventory" {
  depends_on = [
    time_sleep.vm_started_timeout,
    local_file.wf_sys_props,
    local_file.files_for_overwrite,
    local_file.WildFly-group_vars,
  ]

  filename = "ansible/inventory/wildfly_${var.inventory_group_name}.ini"
  content = templatefile("tf_templates/wildfly_inventory.tpl", // todo optimize
  {
    vm_instances = vcd_vapp_vm.SPO_Terraform-Wildfly,
    group_name = var.inventory_group_name
    ansible_user = "ansible"

    json_disks = jsonencode(var.vm_disk_data)
    json_overwrite_files_wildfly = jsonencode(var.overwrite_files_object.files)
    ssh_keys_list = jsonencode(var.ssh_keys_list)
    timestamp = timestamp()

    force_ansible_run: var.force_ansible_run
//    wildfly_version: trimprefix(trimsuffix(basename(var.wildfly_url), ".zip"), "wildfly-")
    wildfly_version: var.wildfly_url
    wildfly_url: var.wildfly_url
    wf_user: "fly"
    wfadminpass: "fly"
    wf_os_user: "wildfly"
    wf_os_user_pwd: "wildfly"
    wf_os_group: "wfgroup"
    wf_install_dir: var.wf_install_dir
    executed_by_terraform : "True"
    PostgreSQL_jdbc_URL: var.postgresql_jdbc_url

  })


  provisioner "local-exec" { // todo опрашивать порт
    #слип sleep
    interpreter = ["bash", "-c"]
    command = "sleep 60"
  }

  // параметры подключения для ансибла
  connection {
    user = "ansible"
    type = "ssh"
    private_key = file("./key.rsa")
    host = ""
  }
  // запуск ансибла по инвентарю (на группу!)
  provisioner "ansible" {
    // provuser
    plays {
      playbook {
        file_path = "ansible/copy_sshkeys.yml"
//        file_path = "ansible/provuser.yml"
      }
      extra_vars = {}
      inventory_file = local_file.WildFly-inventory.filename
      become = true
    }
    // Монтирование дисков
    plays {
      playbook {
        file_path = "ansible/mount-disk.yaml"
      }
      extra_vars = {
         disks = jsonencode(var.vm_disk_data)
      }
      inventory_file = local_file.WildFly-inventory.filename
      become = true
    }
    // Установка репозиториев
    plays {
      playbook {
        file_path = "ansible/setup_vm.yml"
      }
      extra_vars = {}
      inventory_file = local_file.WildFly-inventory.filename
      become = true
    }
    // Установка СПО
    plays {
      playbook {
        file_path = "${local.playbook_path}/main.yml"
        roles_path = [
          "${local.playbook_path}/roles"
        ]
        tags = [
//          "debug",
//          "precheck",
          "install",
//          "configure",
        ]
      }
      inventory_file = local_file.WildFly-inventory.filename
      // переменные лучше подготовить файлом по шаблону
      extra_vars = {
        force_reinstall: var.force_reinstall
        force_update: var.force_update // В соответствии с STD-11 отпри личии версии необходимо упасть
        rolling_update_serial: "50%"

        wildfly_version: var.wildfly_url
//        wildfly_url: var.wildfly_url
//        wildfly_version: trimprefix(trimsuffix(basename(var.wildfly_url), ".zip"), "wildfly-")
        nexusUser: var.nexususer
        nexusPass: var.nexuspass
      }
      verbose = true
      groups = [
        var.inventory_group_name]
    }
    ansible_ssh_settings {
      insecure_no_strict_host_key_checking = true
    }
  }
}

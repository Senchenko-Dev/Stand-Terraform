variable "inventory_path" {}
variable "inventory_group_name" {}
variable "awx_props" {}
variable "spo_role_name" {}
variable "awx_tags" {
  default = ""
}
variable "ans_props" {}
variable "hosts" {}

resource "null_resource" "awx-setup-group" {
  triggers = {
  //  iinventory_sum = sha1(file("ansible/inventory/nginx_${var.inventory_group_name}.ini"))
  //  timestamp = timestamp()
    hosts = "${jsonencode(var.hosts)}",
    group =  var.inventory_group_name
  }
  // параметры подключения для ансибла
  connection {
    host = "localhost"
  }
  // запуск ансибла
  provisioner "ansible" {
    plays {
      playbook {
        file_path = "ansible/awx_config_all.yml"
        tags = ["group"]
      }
      hosts = ["localhost"]
      verbose = true
      extra_vars = merge({
        group_name = var.inventory_group_name,
        vault_file = var.ans_props.vault_file,
        inventory_path = var.inventory_path,
        spo_role_name = var.spo_role_name,
       },
      var.awx_props
      )
      vault_id = ["./ansible/login.sh"]
    }

    ansible_ssh_settings {
      insecure_no_strict_host_key_checking = true
    }
  }

}

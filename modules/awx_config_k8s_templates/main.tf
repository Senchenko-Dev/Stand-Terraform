variable "kubeconfig" {}

variable "meta" {}
variable "awx_props" {}
variable "vault_file" {}

resource "null_resource" "awx-k8s-templates-config" {
  //triggers = {
  //  timestamp = timestamp()
  //}
  // параметры подключения для ансибла
  connection {
    host = "localhost"
  }
  // запуск ансибла
  provisioner "ansible" {
    plays {
      playbook {
        file_path = "ansible/awx_config_all.yml"
        tags = ["purge-template"]
      }
      hosts = ["localhost"]
      verbose = true
      extra_vars = merge({
        vault_file: var.vault_file #"vault_secret.yml"
        kubeconfig: var.kubeconfig
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

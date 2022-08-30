resource "local_file" "ansible_password" {
  filename = "${local.ans_props.vault_passwd_file}"
  content = "${local.ans_props.vault_passwd}"
  file_permission = "0600"
}

provider "ansiblevault" {
  root_folder = "."
  vault_pass  = local.ans_props.vault_passwd
}
data "ansiblevault_path" "path" {
  path = "./ansible/${local.ans_props.vault_file}"
}

locals {
  s = yamldecode(data.ansiblevault_path.path.value)
  secrets = local.s.secrets
}

locals {
  ans_props = {
    vault_file = "ansible/group_vars/all/secrets.yml"
    vault_passwd = var.vault_password
    vault_passwd_file = "ansible_password.txt"
    # hc_vault_disable = var.hashicorpVaultDisable
  }
}

variable "hashicorpVaultDisable" {
  type = string
  default = "yes"
}
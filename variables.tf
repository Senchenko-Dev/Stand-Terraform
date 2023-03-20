// Статические
// Динамические
variable "scm_username" {}

variable "scm_password" {}

variable "scm_url" {
//default = "ssh://git@base.sw.sbc.space:7999/corepltfrm/spo_terraform.git"
}

variable "scm_branch" {
//  default = "master"
}

//variable "nexususer" {
//    description = "Имя пользователя для аутентификации при скачивании дистрибутивов"
//    type = string
//    sensitive = true
//}
//variable "nexuspass" {
//    description = "Пароль пользователя для аутентификации при скачивании дистрибутивов"
//    type = string
//    sensitive = true
//}

variable "BUILD_URL" {
    description = "Ссылка на лог дженкинс"
    type = string
    sensitive = false
    default = "данные отсутствуют"
}

variable "host" {
  type = string
//  default = "https://api.stands-vdc03.solution.sbt:6443"
}

variable "secret_file" {
  type = string
  default = "ansible/secrets.yml"
}

variable "vault_password" {
  type = string
  sensitive = false
  default = "" # "P@ssw0rd!,"
}

variable "hashicorp_vault_url" {
  type = string
  sensitive = false
  default = "" 
}

variable "hashicorp_vault_token" {
  type = string
  sensitive = false
  default = ""
}

variable "managment_system_type" {
  type = string
  default = "openshift"
}

variable "vm_count" {
  default = 0
}


#variable "vcd_username" {}
#
#variable "vcd_password" {}

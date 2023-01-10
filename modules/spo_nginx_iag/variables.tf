# Input variable definitions
variable "vm_count" {
  default = 1
}
variable "vm_props" {}
variable "vm_disk_data" {
  default = []
}
variable "memory" {
  description = "RAM of Virtual Machine"
  type = number
  default = 1024
}
variable "cpu" {
  description = "CPU of Virtual Machine"
  type = number
  default = 1
}

variable "inventory_group_name" {
  description = "Имя группы в инвентаре Ansible"
  type = string
}
variable "vault_file" {
  description = "Имя файла с зашифрованными переменными, расположенного по пути ./ansible/"
}
variable "force_ansible_run" {
  default = false
  description = "Для принудительного запуска ансибл изменить значение"
}
variable "spo_role_name" {
  default = "nginx_iag"
}
variable "nginx_iag_url" {
//  default = ""
}

variable "vault_file" {}

variable "awx_props" {
  default = {}
}

variable "spo_role_name" {
  description = "Переменная для использования альтернативной роли (например, для тестирования обновленной версии.)"
  default = "kafka"
}

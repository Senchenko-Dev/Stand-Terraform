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
  description = "inventory_group_name"
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
  default = "nginx_sgw"
}
variable "nginx_sgw_url" {
//  default = ""
}

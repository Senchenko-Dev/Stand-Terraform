# Input variable definitions
variable "inventory_group_name" {
  description = "Имя группы в инвентаре Ansible"
  type = string
}
variable "vm_count" {
  default = 1
  description = "Установить '0' при использовании внешнего AWX, для его настройки на стенд. Иначе установить '1' или не указывать."
}
variable "vm_props" {
  description = "Набор параметров образа виртуальной машины. vm_props = local.vm_props_default"
}
variable "vm_disk_data" {
  description = "Список монтируемых дисков."
  default = []
}
variable "spo_role_name" {
  description = "Переменная для использования альтернативной роли (например, для тестирования обновленной версии.)"
  default = "awx"
}

variable "memory" {
  description = "RAM of Virtual Machine"
  type = number
  default = 8192
  validation {
    condition = var.memory >= 8192
    error_message = "TOO LOW MEMORY! Must be >= 8192."
  }
}
variable "cpu" {
  description = "CPU of Virtual Machine"
  type = number
  default = 5
  validation {
    condition = var.cpu >= 5
    error_message = "TOO FEW CPU! Must be >= 5."
  }
}

variable "force_ansible_run" {default = "000"}
locals {
  playbook_path = "${abspath(path.root)}"
}

//variable "awx_superadmin_password" {
//  default = "password"
//}

variable "awx_props" {
  description = "Набор параметров для настройки AWX. Для новой установки задайте local.install_awx_props. Для внешнего AWX задайте local.external_awx_props"
}

variable "vault_file" {
  description = "Имя файла с зашифрованными переменными, расположенного по пути ./ansible/"
}

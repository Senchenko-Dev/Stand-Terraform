# Input variable definitions
variable "vm_count" {
  description = "Количество идентичных машин в кластере"
}
variable "vm_props" {
  description = "Набор параметров образа виртуальной машины. vm_props = local.vm_props_default"
}
variable "vm_disk_data" {
  description = "Список монтируемых дисков."
  default = []
}

variable "memory" {
  description = "RAM of Virtual Machine"
  type = number
  default = 8*1024
}

variable "cpu" {
  description = "CPU of Virtual Machine"
  type = number
  default = 4
}

//variable "nexus_cred" {}

variable "inventory_group_name" {
  description = "Имя группы в инвентаре Ansible"
  type = string
}

variable "force_ansible_run" {
  default = false
  description = "Для принудительного запуска ансибл изменить значение"
}

locals {
  playbook_path = "${abspath(path.root)}/ansible/roles/kafka/"
}

variable "force_reinstall" {
  default = false
}

variable "force_update" {
  default = false
}

variable "kafka_url" {
  default = ""
}

variable "vault_file" {
  description = "Имя файла с зашифрованными переменными, расположенного по пути ./ansible/"
}
variable "awx_props" {
  default = {}
}

variable "spo_role_name" {
  description = "Переменная для использования альтернативной роли (например, для тестирования обновленной версии.)"
  default = "kafka"
}
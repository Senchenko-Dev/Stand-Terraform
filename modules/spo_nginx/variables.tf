# Input variable definitions
variable "inventory_group_name" {
  description = "Имя группы в инвентаре Ansible"
  type = string
}
variable "vm_count" {
  description = "Количество идентичных машин в группе"
}
variable "vm_props" {
  description = "Набор параметров образа виртуальной машины. vm_props = local.vm_props_default"
}
variable "vm_disk_data" {
  description = "Список монтируемых дисков. Например, vm_disk_data = [{ size: \"350G\", mnt_dir: \"/KAFKA\" , owner: \"kafka\", group: \"kafka\", mode: \"0755\"}] "
}

variable "spo_role_name" {
  description = "Переменная для использования альтернативной роли (например, для тестирования обновленной версии.)"
  default = "nginx"
}
variable "vault_file" {
  description = "Имя файла с зашифрованными переменными, расположенного по пути ./ansible/"
}

variable "memory" {
  description = "RAM of Virtual Machine"
  type = number
  default = 1024
}
variable "cpu" {
  description = "CPU of Virtual Machine"
  type = number
  default = 2
}

variable "awx_props" {
  description = "Набор параметров для настройки AWX"
  default = {}
}

variable "force_ansible_run" {default = "000"}


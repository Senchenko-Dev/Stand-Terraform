# Input variable definitions
variable "vm_count" {
  default = 1
}

variable "vm_props" {}
variable "vm_disk_data" {
  default = []
}

variable "spo_role_name" {
  default = "nginx_iag"
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

//variable "nexus_cred" {}

variable "inventory_group_name" {
  description = "inventory_group_name"
  type = string
}

variable "force_ansible_run" {
  default = false
  description = "Для принудительного запуска ансибл изменить значение"
}


variable "nginx_iag_url" {
//  default = ""
}

# Input variable definitions
variable "inventory_group_name" {
  description = "inventory_group_name"
  type = string
}
variable "vm_count" {}
variable "vm_props" {}
variable "vm_disk_data" {}
variable "ansible_extra_vars" {
  default = {}
}
variable "spo_role_name" {
  default = "nginx"
}
variable "ans_props" {}

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
  default = {}
}

variable "force_ansible_run" {default = "000"}


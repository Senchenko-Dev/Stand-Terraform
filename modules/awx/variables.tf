# Input variable definitions
variable "inventory_group_name" {
  description = "inventory_group_name"
  type = string
}
variable "vm_count" {
  default = 1
}
variable "vm_props" {}
variable "vm_disk_data" {
  default = []
}
variable "ansible_extra_vars" {
  default = {}
}
variable "spo_role_name" {
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

variable "awx_props" {}

variable "ans_props" {}

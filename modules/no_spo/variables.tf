# Input variable definitions

variable "stand_name" {
  description = "vapp name as stand name"
}

variable "network_name" {
  description = "Name of VCD cluster"
  type = string
}

variable "inventory_group_name" {
  description = "inventory_group_name"
  type = string
}

variable "vm_vm_list" {
  description = " map vm"
  type = list(string)
}

variable "vm_disk_data" {
  default = []
}

variable "catalog_name" {
  description = "VM OS catalog name"
  type = string
  default = "Custom"
}

variable "template_name" {
  description = "VM OS template name"
  type = string
  default = "CentOS7_64-bit_custom2"
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


variable "network_type" {
  description = "Type Of network"
  type = string
  default = "org"
}

variable "ip_allocation_mode" {
  description = "Type mode of ip_allocation_mode"
  type = string
  default = "POOL"
}

variable "ssh_keys_list" {}
variable "force_ansible_run" {default = "000"}

variable "overwrite_files_object" {
  default = {
    files = [
      //      { src : "полное имя файла или шаблона", dest : "целевая директория", args: "словарь переменных для шаблона"},
      //      { src : "", dest : ""},
    ],
    args = {
      key: "value",
    }
  }
}
variable "custom_templates_vm" {default = []}

locals {
}
variable "vm_props" {}
variable "vm_pg_disk_data" {
  default = []
}

variable "vm_etcd_disk_data" {
  default = []
}

variable "memory" {
  description = "RAM of Virtual Machine"
  type = number
  default = 4096
  validation {
    condition = (var.memory >= 2048)
    error_message = "RAM  must be set 2048 or more!"
  }
}

variable "cpu" {
  description = "CPU of Virtual Machine"
  type = number
  default = 1
}

variable "memory_etcd" {
  description = "RAM of etcd Virtual Machine"
  type = number
  default = 1024
}

variable "cpu_etcd" {
  description = "CPU of etcd Virtual Machine"
  type = number
  default = 1
}

variable "nexus_cred" {
  default = {
    nexususer = "",
    nexuspass = "",
  }
//  sensitive = true
}

variable "inventory_group_name" {
  description = "inventory_group_name"
  type = string
}

variable "force_ansible_run" {
  default = false
  description = "Для принудительного запуска ансибл изменить значение"
}

locals {
  playbook_path = "${abspath(path.root)}/ansible/ext-pangolin/installer"
}



variable "installation_type" {}
variable "installation_subtype" {}


variable "pangolin_url" {
  default = ""
} 

variable "ans_props" {}
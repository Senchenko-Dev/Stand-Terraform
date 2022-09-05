# Input variable definitions
variable "vm_count" {}
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

//variable "nexus_cred" {}

variable "inventory_group_name" {
  description = "inventory_group_name"
  type = string
}

variable "force_ansible_run" {
  default = false
  description = "Для принудительного запуска ансибл изменить значение"
}

locals {
  playbook_path = "${abspath(path.root)}/ansible/ext-kafka/kafka-ansible-deploy-3.0.3"
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

variable "vault_file" {}
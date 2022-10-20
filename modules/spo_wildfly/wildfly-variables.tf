# Input variable definitions

variable "stand_name" {
  description = "vapp name as stand name"
}

variable "network_name" {
  //  default = var.network_name // Variables may not  be used here.
}
variable "network_type" {
  //  default = var.network_type // Variables may not  be used here.
  default = "org"
}
variable "ip_allocation_mode" {
  //  default = var.ip_allocation_mode // Variables may not  be used here.
  default = "POOL"
}

variable "inventory_group_name" {
  description = "Имя группы в инвентаре Ansible"
  type = string
}

variable "vm_wildfly_list" {
  type = list(string)
}

variable "vm_disk_data" {
  description = "Список монтируемых дисков."}

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
  default = 2048
  validation {
    condition = (var.memory >= 2048)
    error_message = "RAM for WildFly must be set 2048 or more!"
  }
}

variable "cpu" {
  description = "CPU of Virtual Machine"
  type = number
  default = 1
}
variable "guest_properties_common" {
  description = "Обязательная переменная с параметрами гостевого образа"
}

variable "force_ansible_run" {
  default = ""
  description = "Для принудительного запуска ансибл изменить значение"
}

variable "force_reinstall" {
  default = false
}

variable "force_update" {
  default = false
}

variable "nexususer" {
  type = string
  sensitive = false
  default = ""
}
variable "nexuspass" {
  type = string
  sensitive = false
  default = ""
}

variable "wildfly_url" {
  default = "https://download.jboss.org/wildfly/20.0.1.Final/wildfly-20.0.1.Final.zip"
}

variable "oracle_jdbc_url" {
  default = "https://base.sw.sbc.space/nexus/service/local/repositories/Nexus_PROD/content/Nexus_PROD/CI00360902_TECH_CORE/D-09.004.02-01/CI00360902_TECH_CORE-D-09.004.02-01-distrib.zip"
  //  default = "https://base.sw.sbc.space/nexus/service/local/repositories/Nexus_PROD/content/Nexus_PROD/CI00360902_TECH_CORE/D-09.004.02-01/CI00360902_TECH_CORE-D-09.004.02-01-distrib.zip"
}
variable "postgresql_jdbc_url" {
  default = "https://jdbc.postgresql.org/download/postgresql-42.3.1.jar"
  // default = "https://base.sw.sbc.space/nexus/service/local/repositories/Nexus_PROD/content/Nexus_PROD/CI00360902_TECH_CORE/D-09.004.08-01/CI00360902_TECH_CORE-D-09.004.08-01-distrib.zip"
}

variable "wf_install_dir" {
//  default = "/usr/WF"
  type = string
}

variable "wf_props" {
  default = {}
}

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

variable "ssh_keys_list" {}


variable "custom_templates_wildfly" {default = []}

locals {
  playbook_path = "${abspath(path.root)}"
}
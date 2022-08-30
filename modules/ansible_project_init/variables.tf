variable "managment_system_type" {
  type            = string
  description     = "Container management systems (kubernetes or openshift)"

  validation {
    condition     = contains(["openshift", "k8s"], var.managment_system_type)
    error_message = "Valid values for managment_system_type: kubernetes or openshift!"
  }
}

variable "project_name" {
  type            = string
  description     = "Name for namespace or project"
}

//variable "inventory_path" {
//  type            = string
//  description     = "Path for chart directory"
//}

variable "kubeconfig" {
  type            = string
  description     = "kubconfig path"
}

variable "values" {
//  type            = map(any)
  type = any
  description     = "Values passed to chart"
}

#variable "tags" {
#  type            = map(any)
#  description     = "Tags applied to every object created by chart"
#  default         = {}
#}

variable "vault_password" {
  type            = string
  description     = "ansible vault password"
  sensitive       = false
}

#variable "awx_props" {
#  default = {}
#}

//variable "cpu" {
//  type            = number
//  description     = "Project cpu quota"
//}

//variable "mem" {
//  type            = number
//  description     = "Project memory quota"
//}

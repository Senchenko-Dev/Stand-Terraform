variable "managment_system_type" {
  type            = string
  description     = "Container management systems (kubernetes or openshift)"

  validation {
    condition     = contains(["openshift", "k8s"], var.managment_system_type)
    error_message = "Valid values for managment_system_type: kubernetes or openshift!"
  }
}

variable "kubeconfig" {
  type            = string
  description     = "kubconfig path"
}

variable "globals" {
//  type            = map(any)
  type = any
  description     = "Globals"
}

variable "group" {
  type = any
  description     = "group"
}

variable "specs" {
  //  type            = map(any)
  type = any
  description     = "attributes"
}

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
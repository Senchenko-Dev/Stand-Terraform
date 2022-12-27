terraform {
#  backend "pg" {}
  backend "kubernetes" {
    secret_suffix    = "state"
    host             = "api.stands-vdc03.solution.sbt:6443"
    config_path      = "ansible/dummy"
    insecure         = true
    namespace        = "tfstate-team-polyakov1" #создается проект руками в openshift
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command = "./ansible/login.sh"
      args = ["--token", "none", "--username","sbt-frontend-std", "--password", "Qwerty!2021", "--host", "https://10.255.8.50:6443", "--kubeconfig", "ansible/oc_kubeconfig"]
    }
  }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 1.1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.8.0"
    }
    openshift = {
      source  = "custom/openshift"
//      source  = "llomgui/openshift"
      version = "~> 1.1"
    }
    ansiblevault = {
      source = "MeilleursAgents/ansiblevault"
      version = "2.2.0"
    }
    vcd = {
      source = "vmware/vcd"
      version = "3.6.0"
    }
  }
  required_version = ">= 0.13"
}


 provider "ansiblevault" {
   root_folder = "."
   vault_pass  = var.vault_password
 }
data "ansiblevault_path" "path" {
  path = "ansible/${local.vault_file}"
}

locals {
  s = yamldecode(data.ansiblevault_path.path.value)
  secrets = local.s.secrets
# //  password = chomp(rsadecrypt(filebase64("encrypted.txt"), file("private.key")))
# //  secrets = yamldecode(rsadecrypt(filebase64(var.secret_file), file(var.private_key_file)))
  # secrets = sensitive(yamldecode(data.ansiblevault_path.path.value))
  oc_kubeconfig = "${abspath(path.root)}/ansible/oc_kubeconfig"
  k8s_kubeconfig = "${abspath(path.root)}/ansible/k8s_kubeconfig"
}



provider "helm" {
  kubernetes {
    host = "api.stands-vdc03.solution.sbt:6443"
    #cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    config_path      = "ansible/dummy"
    insecure         = true
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      command     = "./ansible/login.sh"
      args = ["--token", try(local.secrets.token, "none"), "--username", local.secrets.os.username, "--password", local.secrets.os.password, "--host", var.host, "--kubeconfig", local.oc_kubeconfig]
    }
  }
}

provider "openshift" {
  load_config_file = "false"
  host = var.host
  insecure = true
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command = "./ansible/login.sh"
    args = ["--token", try(local.secrets.token, "none"), "--username", local.secrets.os.username, "--password", local.secrets.os.password, "--host", var.host, "--kubeconfig", local.oc_kubeconfig]
  }
}

provider "kubernetes" {
  host = var.host
  insecure = true
  exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command = "./ansible/login.sh"
      args = ["--token", try(local.secrets.token, "none"), "--host", var.host, "--kubeconfig", local.k8s_kubeconfig]
  }
}

provider "vcd" {
#  user                 = "sbertech_r4_developer"
#  password             = "EOrvX0BSNPCrAXj3fDM_4FGnAspioCqO"
#  user                 = var.vcd_username
#  password             = var.vcd_password

#   ------------------------ R4 ---------------------------------

  user                 = local.secrets.vcd.vcd_username
  password             = local.secrets.vcd.vcd_password
  org                  = "SBERTECH_R4"
  vdc                  = "SBERTECH_R4_VDC02"

#   ------------------------ UI ---------------------------------

#  user                 = local.secrets.vcd.vcd_ui_username
#  password             = local.secrets.vcd.vcd_ui_password
#  org                  = "SBERTECH_UI"
#  vdc                  = "SBERTECH_UI_VDC01"
  # ---------------------------------------------------------


  url                  = "https://vcd-site01.dzo.sbercloud.org/api"
  max_retry_timeout    = "120"
  allow_unverified_ssl = "true"
//  logging = true
//  logging_file = "./apilog.log" # _${timestamp()
}



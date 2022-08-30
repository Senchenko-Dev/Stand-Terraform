terraform {
  required_providers {
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
  }
  required_version = ">= 0.13"
 }

resource "kubernetes_namespace" "this" {
  count = "${var.managment_system_type == "k8s" ? 1 : 0}"
  metadata {
    labels = var.values.labels
    name = var.project_name
  }
}

resource "openshift_project_request" "this" {
  count = "${var.managment_system_type == "openshift" ? 1 : 0}"
  metadata {
    annotations = {
      "openshift.io/description" = "example-description"
      "openshift.io/display-name" = "${var.project_name}"
    }
    labels = var.values.labels
    name = var.project_name
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations, metadata[0].labels]
  }


}

resource "null_resource" "vault_file" {
  triggers = {
    project_name = "${var.project_name}"
    values = "${jsonencode(var.values)}"
  }
  
  provisioner "local-exec" {
    command = "mkdir -p ansible/project_vars && echo ${var.vault_password} > ansible/project_vars/$project_name.txt; echo $content > ansible/project_vars/$project_name.yml; ansible-vault encrypt --vault-id ansible/project_vars/$project_name.txt ansible/project_vars/$project_name.yml"
//    command = " echo $content > project_vars/$project_name.yml;"
    environment = {
      VAULT_PASS = "${var.vault_password}"
      content = "${jsonencode(var.values)}"
      project_name = "${var.project_name}"
    }
  }

  provisioner "ansible" {
    plays {
      playbook {
        file_path = "ansible/k8s_project.yml"
        tags = ["prepare-project"]
      }
      hosts = ["neverusedhost"]
      extra_vars = {
        environment_file = "project_vars/${var.project_name}.yml"
        project = "${var.project_name}"
        kubeconfig = "${var.kubeconfig}"
      }
      vault_id = ["ansible/project_vars/${var.project_name}.txt"]
    }
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ansible/project_vars/${self.triggers.project_name}.yml"
  }
}



#module "config_awx_ansible" {
#  count = "${length(var.awx_props) != 0 ? 1 : 0}"
#  source = "../awx_config_k8s_templates"
#  kubeconfig = "${var.kubeconfig}"
#  awx_props = var.awx_props
#}

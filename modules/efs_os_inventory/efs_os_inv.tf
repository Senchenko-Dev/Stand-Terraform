variable "ans_hosts" {
  default = [
    { name: "main_cluster", openshiftAppsDomain="apps.stands-vdc03.solution.sbt", openshiftCluster="https://api.stands-vdc03.solution.sbt:6443", openshiftCorePlatformProjectName="inner-bf1-inner-bf1-ses-sbmg-sentsov" }
  ]
}

variable "group_name" {
  default = ""
}

resource "local_file" "nginx-inventory" {
  content = templatefile("tf_templates/efs_simple_inventory.tpl",
  {
    ans_hosts = var.ans_hosts
    group_name = var.group_name
  })
  filename = "ansible/inventory/efs/efs_os_inv_${var.group_name}.ini"
}
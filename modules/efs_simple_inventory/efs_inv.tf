variable "inventory_group_name" {
  default = "dummy_group"
}
variable "ans_hosts" {
  default = [
    { name = "dummy", ip = "0.0.0.0"}
  ]
}

resource "local_file" "efs-inventory" {
  content = templatefile("tf_templates/efs_simple_inventory.tpl",
  {
    ans_hosts = var.ans_hosts
    group_name = var.inventory_group_name
  })
  filename = "ansible/inventory/efs/efs_inv_${var.inventory_group_name}.ini"
}
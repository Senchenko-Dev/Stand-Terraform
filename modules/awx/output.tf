output "awx_host_ip" {
  value = "${ var.vm_count != 0 ? vcd_vm.VM-awx[0].network[0].ip : var.awx_props.awx_host }"
}


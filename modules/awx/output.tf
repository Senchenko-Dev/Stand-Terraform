output "awx_host_ip" {
  value = vcd_vm.VM-awx[0].network[0].ip
}


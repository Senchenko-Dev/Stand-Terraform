output "awx_password" {
  // Будет лежать в ансибле register: Admin_Password
  value = "terraform"
}
output "awx_endpoint" {
  # value = "https://${vcd_vm.VM-awx[0].network[0].ip}"
  value = "http://10.42.4.127:30080/"
}

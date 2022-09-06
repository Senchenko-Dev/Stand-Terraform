//  Вы можете получить доступ к выходным данным модуля из конфигурации, вызывающей модуль,
//  с помощью следующего синтаксиса: module.<MODULE NAME>.<OUTPUT NAME>.
//  Выходные данные модуля являются атрибутами, доступными только для чтения.


output "wildfly_version" {
  value = trimsuffix(basename(var.wildfly_url),".zip")
}

output "vm_disk_data" {
  value = var.vm_disk_data
}
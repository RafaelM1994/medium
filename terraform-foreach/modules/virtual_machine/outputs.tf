output "vm_id" {
  value = azurerm_virtual_machine.main[*].id
}

output "vm_name" {
  value = azurerm_virtual_machine.main[*].name
}
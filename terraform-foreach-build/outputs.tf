
output "vm_02_id" {
  value = module.virtual_machines["vm2"].vm_id
}

output "vm_01_name" {
  value = module.virtual_machines["vm1"].vm_name
}
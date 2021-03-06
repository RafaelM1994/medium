locals {
  rg1        = "${var.prefix}-${var.location1}-resources"
  rg2        = "${var.prefix}-${var.location2}-resources"
  subnet1_id = azurerm_subnet.subnet1.id
  subnet2_id = azurerm_subnet.subnet2.id
  virtual_machines = {
    "vm1" = { size = var.vm_size1, location = var.location1, resource_group = local.rg1, subnet_id = local.subnet1_id },
    "vm2" = { size = var.vm_size1, location = var.location1, resource_group = local.rg1, subnet_id = local.subnet1_id },
    "vm3" = { size = var.vm_size1, location = var.location1, resource_group = local.rg1, subnet_id = local.subnet1_id },
    "vm4" = { size = var.vm_size1, location = var.location1, resource_group = local.rg1, subnet_id = local.subnet1_id },
    "vm5" = { size = var.vm_size1, location = var.location1, resource_group = local.rg1, subnet_id = local.subnet1_id },
  }
}

resource "azurerm_resource_group" "rg1" {
  name     = local.rg1
  location = var.location1
}

resource "azurerm_resource_group" "rg2" {
  name     = local.rg2
  location = var.location2
}
resource "azurerm_virtual_network" "vnet1" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
}

resource "azurerm_subnet" "subnet1" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_virtual_network" "vnet2" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
}

resource "azurerm_subnet" "subnet2" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg2.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["10.0.2.0/24"]
}

module "virtual_machines" {

  source   = "./modules/virtual_machine"
  for_each = local.virtual_machines

  vm_name   = each.key
  location  = each.value.location
  vm_size   = each.value.size
  rg_name   = each.value.resource_group
  subnet_id = each.value.subnet_id
  prefix    = var.prefix

}

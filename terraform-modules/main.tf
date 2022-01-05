locals {
    prefix = "terraform"
    location = "eastus2"
    vm_size = "Standard_DS1_v2"
}

resource "azurerm_resource_group" "main" {
  name     = "${local.prefix}-resources"
  location = local.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${local.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

module "virtual_machine1" {
  source = "./modules/virtual_machine"
  location            = azurerm_resource_group.main.location
  rg_name = azurerm_resource_group.main.name
  subnet_id = azurerm_subnet.internal.id
  vm_size = local.vm_size
  prefix = local.prefix
  
}

module "virtual_machine2" {
  source = "./modules/virtual_machine"
  location            = azurerm_resource_group.main.location
  rg_name = azurerm_resource_group.main.name
  subnet_id = azurerm_subnet.internal.id
  vm_size = local.vm_size
  prefix = local.prefix
  
}

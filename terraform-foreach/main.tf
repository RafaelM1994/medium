locals {
  prefix     = "terraform"
  location1  = "eastus"
  location2  = "eastus2"
  vm_size1   = "Standard_DS1_v2"
  vm_size2   = "Standard_B1ms"
  rg1        = "${local.prefix}-${local.location1}-resources"
  rg2        = "${local.prefix}-${local.location2}-resources"
  subnet1_id = azurerm_subnet.subnet1.id
  subnet2_id = azurerm_subnet.subnet2.id
  virtual_machines = {
    "vm1" = { size = local.vm_size1, location = local.location1, resource_group = local.rg1, subnet_id = local.subnet1_id },
    "vm2" = { size = local.vm_size1, location = local.location1, resource_group = local.rg1, subnet_id = local.subnet1_id },
    "vm3" = { size = local.vm_size1, location = local.location1, resource_group = local.rg1, subnet_id = local.subnet1_id },
    "vm4" = { size = local.vm_size1, location = local.location1, resource_group = local.rg1, subnet_id = local.subnet1_id },
    "vm5" = { size = local.vm_size1, location = local.location1, resource_group = local.rg1, subnet_id = local.subnet1_id },
    "vm6" = { size = local.vm_size1, location = local.location1, resource_group = local.rg1, subnet_id = local.subnet1_id },
    "vm7" = { size = local.vm_size1, location = local.location1, resource_group = local.rg1, subnet_id = local.subnet1_id },
    "vm8" = { size = local.vm_size1, location = local.location1, resource_group = local.rg1, subnet_id = local.subnet1_id },
    "vm9" = { size = local.vm_size1, location = local.location1, resource_group = local.rg1, subnet_id = local.subnet1_id },
    "vm10" = { size = local.vm_size1, location = local.location1, resource_group = local.rg1, subnet_id = local.subnet1_id },
    "vm11" = { size = local.vm_size2, location = local.location2, resource_group = local.rg2, subnet_id = local.subnet2_id },
    "vm12" = { size = local.vm_size2, location = local.location2, resource_group = local.rg2, subnet_id = local.subnet2_id },
    "vm13" = { size = local.vm_size2, location = local.location2, resource_group = local.rg2, subnet_id = local.subnet2_id },
    "vm14" = { size = local.vm_size2, location = local.location2, resource_group = local.rg2, subnet_id = local.subnet2_id },
    "vm15" = { size = local.vm_size2, location = local.location2, resource_group = local.rg2, subnet_id = local.subnet2_id },
    "vm16" = { size = local.vm_size2, location = local.location2, resource_group = local.rg2, subnet_id = local.subnet2_id },
    "vm17" = { size = local.vm_size2, location = local.location2, resource_group = local.rg2, subnet_id = local.subnet2_id },
    "vm18" = { size = local.vm_size2, location = local.location2, resource_group = local.rg2, subnet_id = local.subnet2_id },
    "vm19" = { size = local.vm_size2, location = local.location2, resource_group = local.rg2, subnet_id = local.subnet2_id },
    "vm20" = { size = local.vm_size2, location = local.location2, resource_group = local.rg2, subnet_id = local.subnet2_id }
  }
}

resource "azurerm_resource_group" "rg1" {
  name     = local.rg1
  location = local.location1
}

resource "azurerm_resource_group" "rg2" {
  name     = local.rg2
  location = local.location2
}
resource "azurerm_virtual_network" "vnet1" {
  name                = "${local.prefix}-network"
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
  name                = "${local.prefix}-network"
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
  prefix    = local.prefix

}

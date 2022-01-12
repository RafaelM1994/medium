terraform {
  backend "azurerm" {
    resource_group_name  = "test"
    storage_account_name = "storage-accountname"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

#Configure the Azure Provider
provider "azurerm" {
  features {}
}

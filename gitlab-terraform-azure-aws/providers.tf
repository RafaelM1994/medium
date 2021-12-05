terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.68.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "test"
    storage_account_name = "storageaccountname"
    container_name       = "tfstate"
    key                  = "test.terraform.tfstate"
  }
}

#Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}



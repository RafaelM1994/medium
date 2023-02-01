terraform {
    backend "s3" {
    bucket         = "hf-test-sheik"
    key            = "terraform/azure/vm/foreach/terraform.tfstate"
    region         = "us-east-1"
    # dynamodb_table = "terraform-state-locks"
    encrypt        = true
    profile        = "dev"
  }
#   backend "azurerm" {
#     resource_group_name  = "test"
#     storage_account_name = "storage-accountname"
#     container_name       = "tfstate"
#     key                  = "terraform.tfstate"
#   }
# }

#Configure the Azure Provider
provider "azurerm" {
  features {}
}

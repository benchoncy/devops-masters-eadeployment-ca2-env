terraform {
  backend "s3" {
    bucket         = "bstuart-tf-state"
    key            = "devops-masters-eadeployment-ca2-env/terraform.tfstate"
    dynamodb_table = "tf-state-locking-table"
    region         = "eu-west-1"
  }
}

provider "azurerm" {
  features {}
}
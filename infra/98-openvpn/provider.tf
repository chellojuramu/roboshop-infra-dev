terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.33.0" # Terraform AWS provider version
    }
  }
  backend "s3" {
    bucket = "terraform-state-file-s3-23022026" #your s3 vault name
    key    = "roboshop-infra-dev/infra/98-openvpn/terraform.tfstate" #path to the state file in the vault
    region = "us-east-1"
    use_lockfile = true
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}
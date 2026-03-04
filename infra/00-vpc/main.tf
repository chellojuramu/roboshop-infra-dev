module "vpc" {
  source = "git::https://github.com/chellojuramu/roboshop-infra-dev.git//modules/terraform-aws-vpc?ref=main"

  project             = var.project
  environment         = var.environment
  is_peering_required = true
}
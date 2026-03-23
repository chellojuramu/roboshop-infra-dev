module "sg" {
  for_each = toset(var.sg_names)

  source = "git::https://github.com/chellojuramu/roboshop-infra-dev.git//modules/terraform-aws-sg?ref=main"
  project = var.project
  environment = var.environment
  sg_name = replace(each.key, "_", "-")
  vpc_id = local.vpc_id
}
locals {
  ssm_parameters = {
    vpc_id = {
      name  = "/${var.project}/${var.environment}/vpc_id"
      type  = "String"
      value = module.vpc.vpc_id
    }
    public_subnet_ids = {
      name = "/${var.project}/${var.environment}/public_subnet_ids"
      type = "StringList"
      value = join(",", module.vpc.public_subnet_ids)
    }
    private_subnet_ids = {
      name = "/${var.project}/${var.environment}/private_subnet_ids"
      type = "StringList"
      value = join(",", module.vpc.private_subnet_ids)
    }
    database_subnet_ids = {
      name = "/${var.project}/${var.environment}/database_subnet_ids"
      type = "StringList"
      value = join(",", module.vpc.database_subnet_ids)
    }
  }
}
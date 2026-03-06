locals {
  ami_id = data.aws_ami.ramuchelloju.id

  common_tags = {
    Project = var.project
    Environment = var.environment
    Terraform = "true"
  }

  database_subnet_id = split(",", data.aws_ssm_parameter.database_subnet_ids.value)[0]

  mongodb_sg_id = data.aws_ssm_parameter.mongodb_sg_id.value
  redis_sg_id   = data.aws_ssm_parameter.redis_sg_id.value
  ssh_password = data.aws_ssm_parameter.ssh_password.value
  mysql_sg_id   = data.aws_ssm_parameter.mysql_sg_id.value
  rabbitmq_sg_id   = data.aws_ssm_parameter.rabbitmq_sg_id.value
  mysql_role_name = join("-", [
    for name in ["${var.project}","${var.environment}", "mysql"] : title(name)
  ])
  mysql_policy_name = join("", [
    for name in ["${var.project}","${var.environment}", "mysql"] : title(name)
  ])

  databases = {
    mongodb = local.mongodb_sg_id
    redis   = local.redis_sg_id
    mysql  = local.mysql_sg_id
    rabbitmq  = local.rabbitmq_sg_id

  }
}
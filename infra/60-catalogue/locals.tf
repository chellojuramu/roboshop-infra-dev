locals {
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  catalogue_sg_id = data.aws_ssm_parameter.catalogue_sg_id.value
  ami_id = data.aws_ami.ramuchelloju.id
  ssh_password = data.aws_ssm_parameter.ssh_password.value
  private_subnet_id = split(",", data.aws_ssm_parameter.private_subnet_ids.value)[0]
  common_tags = {
    Project     = var.project
    Environment = var.environment
    Terraform   = "true"
  }
}
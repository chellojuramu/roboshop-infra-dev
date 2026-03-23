resource "aws_ssm_parameter" "sg_id" {
  for_each = module.sg
  name  = "/${var.project}/${var.environment}/${each.key}_sg_id"
  type  = "String"
  value = each.value.sg_id
}
resource "aws_ssm_parameter" "parameters" {
  for_each = local.ssm_parameters
  name = "/${var.project}/${var.environment}/${each.key}"
  type = each.value.type
  value = each.value.value
}
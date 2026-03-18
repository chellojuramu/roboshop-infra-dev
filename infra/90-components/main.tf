module "component" {
  for_each = var.components
  source = "git::https://github.com/chellojuramu/roboshop-infra-dev.git//modules/terraform-roboshop-component?ref=main"
  component = each.key
  rule_priority = each.value.rule_priority

}
module "component" {
  for_each = var.components
  source = "git::https://github.com/chellojuramu/roboshop-infra-dev.git//modules/terraform-roboshop-component?ref=main"
  component = each.key
  rule_priority = each.value.rule_priority
  app_version   = var.app_version   # this is passed to component module, which will use it to create launch template with correct app version
}
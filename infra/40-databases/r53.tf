resource "aws_route53_record" "database" {
  for_each = aws_instance.database

  zone_id = var.zone_id
  name    = "${each.key}-${var.environment}.${var.domain_name}"
  type    = "A"
  ttl     = 1

  records = [each.value.private_ip]

  allow_overwrite = true
}
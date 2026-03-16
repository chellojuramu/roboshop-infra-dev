resource "aws_lb" "frontend_alb" {
  name               = "${var.project}-${var.environment}-frontend"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [local.frontend_alb_sg_id]
  subnets            = local.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(
    {
      Name = "${var.project}-${var.environment}-frontend"
    },
    local.common_tags
  )
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = local.frontend_alb_certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/html"
      message_body = "<html><body><h1>frontend ALB is working!</h1></body></html>"
      status_code  = "200"
    }
  }
}
resource "aws_route53_record" "www" {
  zone_id = var.zone_id
  type    = "A"
  name    = "*.${var.domain_name}"
  alias {
    evaluate_target_health = true
    name                   = aws_lb.frontend_alb.dns_name
    zone_id                = aws_lb.frontend_alb.zone_id
  }
  allow_overwrite = true
}
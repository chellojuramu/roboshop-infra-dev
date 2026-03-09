resource "aws_lb" "backend_alb" {
  name               = "${var.project}-${var.environment}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [local.backend_alb_sg_id]
  subnets            = local.private_subnet_ids

  enable_deletion_protection = true

  tags = merge(
    {
        Name = "${var.project}-${var.environment}"
    },
    local.common_tags
  )
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.backend_alb.arn
    port              = "80"
    protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/html"
      message_body = "<html><body><h1>Backend ALB is working!</h1></body></html>"
        status_code  = "200"
  }
}
}
resource "aws_route53_record" "www" {
  zone_id = var.zone_id
  type    = "A"
  name    = "*.backend-alb-${var.environment}.${var.domain_name}"
  alias {
    evaluate_target_health = true
    name                   = aws_lb.backend_alb.dns_name
    zone_id                = aws_lb.backend_alb.zone_id
  }
}
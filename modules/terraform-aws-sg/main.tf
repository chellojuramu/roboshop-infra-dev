resource "aws_security_group" "main" {
  name = "${var.project}-${var.environment}-${var.sg_name}"
  description = "Allow TLS inbound traffic for ${var.project} in ${var.environment} for component ${var.sg_name}"
  vpc_id = var.vpc_id

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.sg_tags,
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-${var.sg_name}"
    }
  )
  }

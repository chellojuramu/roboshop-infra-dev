resource "aws_instance" "openvpn" {
  ami           = local.ami_id
  instance_type = "t3.small"
  subnet_id     = local.public_subnet_id
  vpc_security_group_ids = [local.openvpn_sg_id]

  user_data = file("vpn.sh")
  tags = merge(
    {
      Name = "${var.project}-${var.environment}-openvpn"
    },
    local.common_tags
  )
}

}
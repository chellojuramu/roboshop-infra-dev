resource "aws_instance" "database" {
  for_each = local.databases

  ami                    = local.ami_id
  instance_type          = "t3.micro"
  subnet_id              = local.database_subnet_id
  vpc_security_group_ids = [each.value]

  tags = merge(
    {
      Name = "${var.project}-${var.environment}-${each.key}"
    },
    local.common_tags
  )
}

resource "terraform_data" "bootstrap" {
  for_each = aws_instance.database

  triggers_replace = [
    each.value.id
  ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = local.ssh_password
    host     = each.value.private_ip
  }

  provisioner "file" {
    source      = "bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap.sh",
      "sudo sh /tmp/bootstrap.sh ${each.key}"
    ]
  }
}
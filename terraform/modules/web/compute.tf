data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "web" {
  count                  = var.web_count
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = var.private_web_subnet_id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.key_name
  iam_instance_profile   = "LabInstanceProfile"

  user_data_replace_on_change = true
  user_data = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname web-${count.index + 1}
    dnf update -y
    dnf install -y nginx
    systemctl enable --now nginx
  EOF

  tags = { Name = "${var.project}-web-${count.index + 1}" }
}

resource "aws_lb_target_group_attachment" "web" {
  count            = var.web_count
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}

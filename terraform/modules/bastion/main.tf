data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-kernel-*-x86_64"]
  }
  filter {
    name   = "description"
    values = ["Amazon Linux 2023 AMI *"]
  }
}

resource "aws_security_group" "bastion" {
  name        = "${var.project}-bastion-sg"
  description = "Bastion : SSH depuis IP admin uniquement"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-bastion-sg" }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  iam_instance_profile        = "LabInstanceProfile"

  user_data = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname bastion
    dnf update -y
  EOF

  tags = { Name = "${var.project}-bastion" }
}

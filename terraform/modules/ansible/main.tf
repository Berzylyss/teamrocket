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

resource "aws_security_group" "ansible" {
  name        = "${var.project}-ansible-sg"
  description = "Ansible master : SSH depuis bastion uniquement"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH depuis bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-ansible-sg" }
}

resource "aws_instance" "ansible" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = var.private_web_subnet_id
  vpc_security_group_ids = [aws_security_group.ansible.id]
  key_name               = var.key_name
  iam_instance_profile   = "LabInstanceProfile"

  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/templates/userdata.sh.tftpl", {
    private_key_pem = var.private_key_pem
    s3_bucket_name  = var.s3_bucket_name
    region          = var.region
    ftp_private_ip  = var.ftp_private_ip
  })

  tags = { Name = "${var.project}-ansible-master" }
}

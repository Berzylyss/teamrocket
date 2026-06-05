cat > ~/teamrocket/terraform/modules/monitoring/main.tf << 'TFEOF'
# =============================================================================
# Module monitoring — Prometheus + Grafana
# =============================================================================

variable "project"               { type = string }
variable "vpc_id"                { type = string }
variable "private_web_subnet_id" { type = string }
variable "bastion_sg_id"         { type = string }
variable "web_sg_id"             { type = string }
variable "key_name"              { type = string }
variable "instance_type"         { type = string }
variable "region"                { type = string }
variable "s3_bucket_name"        { type = string }

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "monitoring" {
  name        = "${var.project}-sg-monitoring"
  description = "Supervision : SSH + Grafana 3000 + Prometheus 9090 depuis bastion"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH depuis bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  ingress {
    description     = "Grafana tunnel SSH"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  ingress {
    description     = "Prometheus tunnel SSH"
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  egress {
    description = "Sortant : scraping S3 et mises a jour via NAT"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-sg-monitoring" }
}

resource "aws_security_group_rule" "web_node_exporter" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  security_group_id        = var.web_sg_id
  source_security_group_id = aws_security_group.monitoring.id
  description              = "node-exporter scraping depuis monitoring"
}

resource "aws_instance" "monitoring" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.private_web_subnet_id
  vpc_security_group_ids      = [aws_security_group.monitoring.id]
  key_name                    = var.key_name
  iam_instance_profile        = "LabInstanceProfile"
  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > /var/log/ansible-monitoring.log 2>&1

    # Dependances systeme
    dnf install -y ansible-core aws-cli iptables

    # Collection ansible.posix version compatible ansible-core 2.15
    ansible-galaxy collection install ansible.posix:==1.5.4

    # Recuperer les fichiers Ansible depuis S3
    aws s3 sync s3://${var.s3_bucket_name}/ansible/ /opt/ansible/ \
      --region ${var.region}

    # extra_vars avec retry (peut arriver avant la fin de terraform apply)
    for i in 1 2 3 4 5 6 7 8 9 10; do
      aws s3 cp s3://${var.s3_bucket_name}/ansible/extra_vars.yml \
        /opt/ansible/extra_vars.yml --region ${var.region} && break
      echo "Retry $i/10 dans 15s..."
      sleep 15
    done

    # Lancer le play monitoring en connexion locale
    cd /opt/ansible
    ansible-playbook site.yml \
      --limit monitoring \
      --extra-vars @extra_vars.yml \
      --extra-vars "ansible_connection=local" \
      -i inventory.ini
  EOF

  tags = { Name = "${var.project}-monitoring" }
}

output "private_ip" {
  description = "IP privee du serveur de supervision"
  value       = aws_instance.monitoring.private_ip
}

output "sg_id" {
  description = "ID du Security Group monitoring"
  value       = aws_security_group.monitoring.id
}
TFEOF
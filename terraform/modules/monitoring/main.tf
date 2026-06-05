# =============================================================================
# Module monitoring — Prometheus + Grafana
# Calqué sur le module "ansible" : même subnet (private_web), même SG pattern,
# accès via bastion uniquement. Consulté par tunnel SSH.
#
# Inputs attendus depuis main.tf :
#   source                = "./modules/monitoring"
#   project               = var.project
#   vpc_id                = module.network.vpc_id
#   private_web_subnet_id = module.network.private_web_subnet_id
#   bastion_sg_id         = module.bastion.sg_id
#   web_sg_id             = module.web.web_sg_id
#   key_name              = aws_key_pair.tpfinal.key_name
#   instance_type         = var.instance_type
#   region                = var.region
#   s3_bucket_name        = module.storage.bucket_name
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

# ---- Security Group monitoring ----------------------------------------------
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
    description     = "Grafana (tunnel SSH)"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  ingress {
    description     = "Prometheus (tunnel SSH)"
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  egress {
    description = "Sortant : scraping + S3 + mises à jour via NAT"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-sg-monitoring" }
}

# ---- Ouvrir node-exporter (9100) sur le SG web depuis monitoring ------------
resource "aws_security_group_rule" "web_node_exporter" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  security_group_id        = var.web_sg_id
  source_security_group_id = aws_security_group.monitoring.id
  description              = "node-exporter scraping depuis monitoring"
}

# ---- Instance EC2 monitoring ------------------------------------------------
# Même pattern que le module ansible : user_data bootstrap depuis S3
resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = var.private_web_subnet_id
  vpc_security_group_ids = [aws_security_group.monitoring.id]
  key_name               = var.key_name
  iam_instance_profile   = "LabInstanceProfile"

  user_data = <<-EOF
    #!/bin/bash
    # Bootstrap : installer Ansible depuis S3 et lancer le play monitoring
    dnf install -y ansible-core aws-cli

    # Récupérer les fichiers Ansible depuis S3
    aws s3 sync s3://${var.s3_bucket_name}/ansible/ /opt/ansible/ \
      --region ${var.region}

    # Lancer le play monitoring en local (localhost)
    cd /opt/ansible
    ansible-playbook site.yml \
      --limit monitoring \
      --extra-vars @extra_vars.yml \
      -i inventory.ini \
      2>&1 | tee /var/log/ansible-monitoring.log
  EOF

  tags = { Name = "${var.project}-monitoring" }
}

# ---- Outputs ----------------------------------------------------------------
output "private_ip" {
  description = "IP privée du serveur de supervision"
  value       = aws_instance.monitoring.private_ip
}

output "sg_id" {
  description = "ID du Security Group monitoring"
  value       = aws_security_group.monitoring.id
}

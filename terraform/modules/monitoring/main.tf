# =============================================================================
# Module monitoring — Serveur de supervision (Prometheus + Grafana)
# Instance EC2 privée, accès via tunnel SSH depuis le bastion
#
# USAGE dans votre main.tf :
#   module "monitoring" {
#     source            = "./modules/monitoring"
#     project           = var.project
#     region            = var.region
#     instance_type     = var.instance_type
#     key_name          = aws_key_pair.tpfinal.key_name
#     private_subnet_id = module.network.private_web_subnet_id
#     vpc_id            = module.network.vpc_id
#     bastion_sg_id     = module.bastion.sg_id
#     web_sg_id         = module.web.web_sg_id
#     ftp_sg_id         = module.storage.ftp_sg_id
#   }
#
# ACCÈS Grafana (une fois déployé) :
#   ssh -i ansible/key.pem \
#     -L 3000:<MONITORING_PRIVATE_IP>:3000 \
#     -L 9090:<MONITORING_PRIVATE_IP>:9090 \
#     ec2-user@<BASTION_PUBLIC_IP>
#   → http://localhost:3000  (admin / admin)
#   → http://localhost:9090
# =============================================================================

# ---- Variables --------------------------------------------------------------
variable "project"           { type = string }
variable "region"            { type = string }
variable "instance_type"     { type = string }
variable "key_name"          { type = string }
variable "private_subnet_id" { type = string }
variable "vpc_id"            { type = string }
variable "bastion_sg_id"     { type = string }
variable "web_sg_id"         { type = string }
variable "ftp_sg_id"         { type = string }

# ---- AMI Amazon Linux 2023 (identique aux autres modules) -------------------
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

# ---- Security Group monitoring ----------------------------------------------
# Prometheus 9090 + Grafana 3000 : depuis le bastion uniquement (tunnel SSH)
resource "aws_security_group" "monitoring" {
  name        = "${var.project}-sg-monitoring"
  description = "Supervision : Grafana 3000 + Prometheus 9090 depuis bastion uniquement"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH depuis bastion et Ansible master (VPC)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  ingress {
    description = "SSH depuis Ansible master (subnet prive)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"]
  }

  ingress {
    description     = "Grafana depuis bastion (tunnel SSH)"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  ingress {
    description     = "Prometheus depuis bastion (tunnel SSH)"
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  egress {
    description = "Sortant : scraping node-exporter + mises a jour via NAT"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-sg-monitoring" }
}

# ---- Ouvrir node-exporter (9100) sur les cibles depuis le SG monitoring -----
# À ajouter sur les SG existants web et ftp via aws_security_group_rule
resource "aws_security_group_rule" "web_node_exporter_from_monitoring" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  security_group_id        = var.web_sg_id
  source_security_group_id = aws_security_group.monitoring.id
  description              = "node-exporter scraping depuis monitoring"
}

resource "aws_security_group_rule" "ftp_node_exporter_from_monitoring" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  security_group_id        = var.ftp_sg_id
  source_security_group_id = aws_security_group.monitoring.id
  description              = "node-exporter scraping depuis monitoring"
}

# ---- Instance EC2 monitoring (privée) ---------------------------------------
resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [aws_security_group.monitoring.id]
  key_name               = var.key_name
  iam_instance_profile   = "LabInstanceProfile"

  tags = { Name = "${var.project}-monitoring" }
}

# ---- Outputs ----------------------------------------------------------------
output "monitoring_private_ip" {
  description = "IP privée du serveur de supervision"
  value       = aws_instance.monitoring.private_ip
}

output "sg_monitoring_id" {
  description = "ID du Security Group monitoring"
  value       = aws_security_group.monitoring.id
}

output "tunnel_command" {
  description = "Commande tunnel SSH pour accéder à Grafana et Prometheus"
  value       = "ssh -i ansible/key.pem -L 3000:${aws_instance.monitoring.private_ip}:3000 -L 9090:${aws_instance.monitoring.private_ip}:9090 ec2-user@<BASTION_IP>"
}

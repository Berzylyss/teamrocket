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

# ── KMS — clé de chiffrement S3 ───────────────────────────────────────────────
resource "aws_kms_key" "s3" {
  description             = "${var.project} — chiffrement bucket S3"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = { Name = "${var.project}-s3-kms" }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.project}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

# ── S3 — bucket avec chiffrement KMS ─────────────────────────────────────────
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  bucket_name = lower(replace("${var.project}-storage-${random_string.suffix.result}", "_", "-"))
}

resource "aws_s3_bucket" "main" {
  bucket        = local.bucket_name
  force_destroy = true
  tags          = { Name = local.bucket_name }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket                  = aws_s3_bucket.main.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration { status = "Enabled" }
}

# ── Security Group FTP ────────────────────────────────────────────────────────
resource "aws_security_group" "ftp" {
  name        = "${var.project}-ftp-sg"
  description = "FTP : SSH/FTP depuis le VPC uniquement"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH depuis bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  ingress {
    description = "SSH depuis Ansible master (subnet prive web)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"]
  }

  ingress {
    description = "FTP control"
    from_port   = 21
    to_port     = 21
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "FTP passif data"
    from_port   = 21100
    to_port     = 21110
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-ftp-sg" }
}

# ── Mot de passe FTP généré (jamais en clair dans le code) ───────────────────
resource "random_password" "ftp_user" {
  length           = 16
  special          = true
  override_special = "#$-_=+"
}

# ── EC2 FTP — user_data minimal, vsftpd configuré intégralement par Ansible ──
resource "aws_instance" "ftp" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = var.private_storage_subnet_id
  vpc_security_group_ids = [aws_security_group.ftp.id]
  key_name               = var.key_name
  iam_instance_profile   = "LabInstanceProfile"

  user_data_replace_on_change = true
  user_data = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname ftp-01
  EOF

  tags = { Name = "${var.project}-ftp" }
}

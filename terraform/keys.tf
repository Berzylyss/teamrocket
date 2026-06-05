# Genere une paire de cles SSH (utilisee pour le Master ET les cibles)
resource "tls_private_key" "tpfinal" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "tpfinal" {
  key_name   = "${var.project}-key"
  public_key = tls_private_key.tpfinal.public_key_openssh
}

# Ecrit la cle privee dans le dossier ansible/ (pour SSH + Ansible)
resource "local_file" "private_key" {
  content         = tls_private_key.tpfinal.private_key_pem
  filename        = "${path.module}/../ansible/tpfinal.pem"
  file_permission = "0600"
}

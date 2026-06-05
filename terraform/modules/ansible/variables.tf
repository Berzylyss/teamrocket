variable "project" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_web_subnet_id" {
  type = string
}

variable "bastion_sg_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "private_key_pem" {
  description = "Clé SSH privée (écrite dans ~/.ssh/id_rsa sur l'Ansible master)"
  type        = string
  sensitive   = true
}

variable "s3_bucket_name" {
  type = string
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "ftp_private_ip" {
  description = "IP privée du serveur FTP — incluse dans user_data pour forcer le remplacement de l'Ansible master si le FTP change"
  type        = string
}

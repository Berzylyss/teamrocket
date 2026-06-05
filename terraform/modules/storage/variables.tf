variable "project" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_storage_subnet_id" {
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

variable "region" {
  type    = string
  default = "us-east-1"
}

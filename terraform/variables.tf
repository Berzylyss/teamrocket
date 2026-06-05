variable "region" {
  description = "Region AWS imposee par AWS Academy"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Prefixe de nommage des ressources"
  type        = string
  default     = "tpfinal"
}

variable "my_ip" {
  description = "Votre IP publique au format CIDR /32 (voir whatismyip)"
  type        = string
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.micro"
}

variable "web_count" {
  description = "Nombre d'instances web derriere l'ALB"
  type        = number
  default     = 2
}

output "public_ip" {
  description = "IP publique du bastion"
  value       = aws_instance.bastion.public_ip
}

output "private_ip" {
  description = "IP privée du bastion"
  value       = aws_instance.bastion.private_ip
}

output "sg_id" {
  description = "ID du security group bastion (utilisé par les autres modules)"
  value       = aws_security_group.bastion.id
}

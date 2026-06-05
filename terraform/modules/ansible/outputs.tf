output "private_ip" {
  description = "IP privée de l'Ansible master"
  value       = aws_instance.ansible.private_ip
}

output "sg_id" {
  value = aws_security_group.ansible.id
}

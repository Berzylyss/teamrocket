output "vpc_id" {
  description = "ID du VPC"
  value       = module.network.vpc_id
}

output "bastion_public_ip" {
  description = "IP publique du bastion (SSH : ssh -i ansible/tpfinal.pem ec2-user@<IP>)"
  value       = module.bastion.public_ip
}

output "bastion_private_ip" {
  description = "IP privee du bastion"
  value       = module.bastion.private_ip
}

output "alb_https_url" {
  description = "URL HTTPS de l'ALB (certificat auto-signe : ignorer l'avertissement navigateur)"
  value       = "https://${module.web.alb_dns_name}"
}

output "web_private_ips" {
  description = "IPs privees des serveurs web (accessibles via bastion)"
  value       = module.web.private_ips
}

output "ansible_master_private_ip" {
  description = "IP privee de l'Ansible master (ProxyJump via bastion)"
  value       = module.ansible.private_ip
}

output "ftp_private_ip" {
  description = "IP privee du serveur FTP (ProxyJump via bastion)"
  value       = module.storage.ftp_private_ip
}

output "s3_bucket_name" {
  description = "Nom du bucket S3 (chiffrement KMS)"
  value       = module.storage.bucket_name
}

output "kms_key_id" {
  description = "ID de la cle KMS utilisee pour le bucket S3"
  value       = module.storage.kms_key_id
}

output "ssh_bastion" {
  description = "Commande SSH vers le bastion"
  value       = "ssh -i ansible/tpfinal.pem ec2-user@${module.bastion.public_ip}"
}

output "ssh_web_via_bastion" {
  description = "Commande SSH vers web-1 via bastion"
  value       = "ssh -i ansible/tpfinal.pem -J ec2-user@${module.bastion.public_ip} ec2-user@${try(module.web.private_ips[0], "N/A")}"
}

output "ssh_ansible_via_bastion" {
  description = "Commande SSH vers l'Ansible master via bastion"
  value       = "ssh -i ansible/tpfinal.pem -J ec2-user@${module.bastion.public_ip} ec2-user@${module.ansible.private_ip}"
}

output "monitoring_private_ip" {
  description = "IP privée du serveur de supervision"
  value       = module.monitoring.private_ip
}

output "tunnel_grafana" {
  description = "Tunnel SSH pour accéder à Grafana (puis http://localhost:3000) et Prometheus (http://localhost:9090)"
  value       = "ssh -i ansible/tpfinal.pem -L 3000:${module.monitoring.private_ip}:3000 -L 9090:${module.monitoring.private_ip}:9090 ec2-user@${module.bastion.public_ip}"
}

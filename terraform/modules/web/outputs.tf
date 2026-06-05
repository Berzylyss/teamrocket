output "private_ips" {
  description = "IPs privées des instances web"
  value       = aws_instance.web[*].private_ip
}

output "alb_dns_name" {
  description = "DNS de l'ALB (HTTPS)"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  value = aws_lb.main.arn
}

output "web_sg_id" {
  value = aws_security_group.web.id
}

output "bucket_name" {
  description = "Nom du bucket S3"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  value = aws_s3_bucket.main.arn
}

output "kms_key_id" {
  description = "ID de la clé KMS S3"
  value       = aws_kms_key.s3.key_id
}

output "kms_key_arn" {
  value = aws_kms_key.s3.arn
}

output "ftp_private_ip" {
  description = "IP privée du serveur FTP"
  value       = aws_instance.ftp.private_ip
}

output "ftp_user_password" {
  description = "Mot de passe généré pour l'utilisateur FTP (sensible)"
  value       = random_password.ftp_user.result
  sensitive   = true
}

output "ftp_sg_id" {
  description = "ID du Security Group FTP"
  value       = aws_security_group.ftp.id
}

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

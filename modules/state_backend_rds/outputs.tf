output "rds_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.tf_rds_backend.address
  #   sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.tf_rds_backend.port
  #   sensitive   = true
}

output "rds_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.tf_rds_backend.username
  #   sensitive   = true
}

output "rds_kms_key_id" {
  description = "RDS KMS Key"
  value       = aws_kms_key.tf_rds_backend.id

}

output "rds_managed_secret" {
  value = aws_db_instance.tf_rds_backend.master_user_secret
}
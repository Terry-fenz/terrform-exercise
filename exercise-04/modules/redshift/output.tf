# Redshift cluster 的 id
output "cluster_id" {
  description = "Redshift cluster id"
  value       = module.redshift.cluster_id
}

# EC2 的預設安全群組 id
output "default_security_group_id" {
  description = "Default security group id for redshift cluster"
  value       = aws_security_group.redshift.id
}

# Redshift 的公開 endpoint，用於資料庫連線
output "cluster_endpoint" {
  description = "Redshift cluster endpoint"
  value       = module.redshift.cluster_endpoint
}

# Redshift 的 secret arn，用於 DMS 資料庫連線
output "secret_arn" {
  description = "Redshift cluster connect secret_arn"
  value       = module.redshift_secrets_manager.secret_arn
}
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
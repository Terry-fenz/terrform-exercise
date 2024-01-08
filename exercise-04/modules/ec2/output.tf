# EC2 的 id
output "id" {
  description = "EC2 id"
  value       = aws_instance.ec2.id
}

# EC2 的預設安全群組 id
output "default_security_group_id" {
  description = "Default security group id for ec2"
  value       = aws_security_group.ec2.id
}

# EC2 的公開 DNS，用於 ssh 連線
output "public_dns" {
  description = "EC2 public dns"
  value       = aws_instance.ec2.public_dns
}

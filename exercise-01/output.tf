# 新建 vpc id
output "vpc_id" {
  description = "vpc id"
  value       = module.vpc.vpc_id
}

# ec2 的公開 DNS，用於 ssh 連線
output "data_center_ec2_public_dns" {
  description = "datacenter ec2 public dns"
  value       = aws_instance.data_center_ec2.public_dns
}

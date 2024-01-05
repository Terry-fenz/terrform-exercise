# 新建 vpc id
output "vpc_id" {
  description = "vpc id"
  value       = module.vpc.vpc_id
}

# ec2 的公開 dns，用於 ssh 連線
# ssh連線指令：ssh -i ssh_key.pem ec2-user@${aws_instance.ec2.public_dns}
output "ec2_public_dns" {
  description = "ec2 public dns"
  value       = module.ec2.public_dns
}

# 產生 ssh key 工具
resource "tls_private_key" "pk" {
  algorithm = var.algorithm
  rsa_bits  = var.rsa_bits
}

# 至 aws 註冊新的 ssh key
resource "aws_key_pair" "ssh_key" {
  key_name   = var.key_name
  public_key = tls_private_key.pk.public_key_openssh

  tags = var.tags
}

# 在本地輸出 pem 檔案
resource "local_file" "ssh_key" {
  content  = tls_private_key.pk.private_key_pem
  filename = var.filename
  file_permission = "0400"
}

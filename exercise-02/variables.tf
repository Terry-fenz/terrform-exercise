# aws region
variable "region" {
  description = "aws region"
  type        = string
  default     = "ap-southeast-1" # 新加坡
}

# ec2 的執行個體類型
variable "instance_type" {
 description = "ec2 instance type"
 type = string
 default = "t2.micro"
}

# 開放 ssh 連線的 cidr block
variable "ssh_cidr" {
 type = string
 default = "0.0.0.0/0"
 description = "cidr block for ssh"
}

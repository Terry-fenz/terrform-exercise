# EC2 的執行個體名稱
variable "name" {
  description = "EC2 instance name"
  type        = string
}

# EC2 的執行個體類型
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

# EC2 所屬 VPC ID
variable "vpc_id" {
  description = "VPC id for ec2 instance"
  type        = string
}

# EC2 對應的子網域 id
variable "subnet_id" {
  description = "Subnet id for ec2 instance"
  type        = string
}

# EC2 ssh key 名稱 
variable "key_name" {
  description = "SSH key name of aws key pair"
  type        = string
}

# 開放 SSH 連線的 cidr block
variable "ssh_cidr" {
  type        = string
  description = "CIDR block for ssh"
}

# EC2 tags
variable "tags" {
  description = "EC2 tags"
  type        = map(string)
  default     = {}
}

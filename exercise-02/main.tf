# 定義狀態檔存放位置
terraform {
  backend "s3" {
    bucket = "data-center-terraform"
    key    = "terraform.tfstate"
    region = "ap-southeast-1" # 新加坡

    shared_credentials_files = ["./../.aws/credentials"]
  }
}

# provider
provider "aws" {
  region                   = var.region
  shared_credentials_files = ["./../.aws/credentials"]
  profile                  = "default"
}

# 定義變數
locals {
  project_name = "data-center"                                  # 專案基礎名稱
  name         = "${local.project_name}-${terraform.workspace}" # 專案名稱，以 workspace 區分環境

  vpc_cidr = "10.0.0.0/16"                                            # VPC CIDR
  azs      = slice(data.aws_availability_zones.available.names, 0, 1) # AWS 可用區域，這裡只取第一個

  # 通用 tag
  tags = {
    Project_Name = local.project_name
    Terraform    = "true"
    Environment  = terraform.workspace
  }
}

# 取得 aws 資源
data "aws_availability_zones" "available" {} # AWS 可用區域

# 建立一個 vpc
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs = local.azs

  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 1)]

  enable_nat_gateway           = true
  single_nat_gateway           = true
  create_database_subnet_group = true
  enable_dns_hostnames         = true

  tags = local.tags
}

# 產生 ssh key 工具
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 至 aws 註冊新的 ssh key
resource "aws_key_pair" "ssh_key" {
  key_name   = "${local.name}-ssh-key"
  public_key = tls_private_key.pk.public_key_openssh

  tags = local.tags
}

# ssh_key 在本地 pem 檔案
resource "local_file" "ssh_key" {
  content  = tls_private_key.pk.private_key_pem
  filename = "ssh_key.pem"

  # 檔案新增後，修改權限
  provisioner "local-exec" {
    command = "chmod 400 ssh_key.pem"
  }
}

# 取得 ec2 使用映象檔
# 查詢指令：aws ec2 describe-images --region ap-southeast-1 --filters "Name=name, Values=al2023-ami-2023*x86_64*" |grep \"Name
data "aws_ami" "amazon_linux_2023_ami" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023*x86_64*"]
  }
}

# 建立一個 ec2
resource "aws_instance" "data_center_ec2" {
  instance_type = var.instance_type
  ami           = data.aws_ami.amazon_linux_2023_ami.id
  key_name      = aws_key_pair.ssh_key.key_name

  vpc_security_group_ids      = ["${aws_security_group.data_center_ec2.id}"] # 請使用 vpc_security_group_ids，而不是 security_group，否則會每次執行時都重建 aws_instance
  associate_public_ip_address = true # 開放公開 DNS，用於 ssh 連線

  subnet_id = module.vpc.public_subnets[0] # subnet 需配置 vpc 的 public subnet，才可從公開 DNS 連線

  user_data = file("./script/init_docker.sh") # show log in ec2: /var/log/cloud-init-output.log

  tags = merge({
    "Name" : "${local.name}-ec2"
  }, local.tags)
}

# 建立 ec2 專用安全群組
resource "aws_security_group" "data_center_ec2" {
  description = "security group for ${local.name}-ec2"
  name        = "${local.name}-ec2"
  vpc_id      = module.vpc.vpc_id

  tags = local.tags

  # 開放往內 ssh
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr] # 使用 variable 輸入，預設全開放
  }

  # 開放往外 http、https (下載套件、更新用)
  egress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 開放往外呼叫 harbor
  # TODO: Change for production
  egress {
    description = "harbor"
    from_port   = 8070
    to_port     = 8070
    protocol    = "tcp"
    cidr_blocks = ["54.251.6.240/32"]
  }
}

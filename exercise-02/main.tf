# 定義狀態檔存放位置
terraform {
  backend "s3" {
    bucket = "data-center-terraform"
    key    = "terraform.tfstate"
    region = "ap-southeast-1" # 新加坡

    shared_credentials_files = ["./../.aws/credentials"] # aws 認證設定，預設應為 ~/.aws/credentials
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

  name = "${local.name}-vpc"
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

# 至 aws 註冊新的 ssh key
module "ssh_key" {
  source = "./modules/ssh-key"

  key_name = "${local.name}-ssh-key"
  filename = "./ssh_key.pem"

  tags = local.tags
}

# 建立一個 ec2
module "ec2" {
  source = "./modules/ec2"

  # 基本設定
  name          = "${local.name}-ec2"
  instance_type = var.instance_type

  # 網路設定
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0] # subnet 需配置 vpc 的 public subnet，才可從公開 DNS 連線

  # ssh 連線設定
  key_name = module.ssh_key.key_name
  ssh_cidr = var.ssh_cidr

  tags = local.tags
}

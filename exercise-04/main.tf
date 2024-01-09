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
  shared_credentials_files = ["./../.aws/credentials"] # aws 認證設定，預設應為 ~/.aws/credentials
  profile                  = "default"
}

# 定義變數
locals {
  project_name = "data-center"                                  # 專案基礎名稱
  name         = "${local.project_name}-${terraform.workspace}" # 專案名稱，以 workspace 區分環境

  vpc_cidr = "10.0.0.0/16"                                            # VPC CIDR
  azs      = slice(data.aws_availability_zones.available.names, 0, 3) # AWS 可用區域，取前三個

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
# 假如要使用現有 vpc，後續步驟請用 vpc_id 指定，或使用 resource 取代
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name}-vpc"
  cidr = local.vpc_cidr

  azs = local.azs

  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 3)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 6)]
  redshift_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 9)]

  enable_nat_gateway           = true
  single_nat_gateway           = true
  create_database_subnet_group = true
  enable_dns_hostnames         = true
  enable_public_redshift       = true # 開放 redshift 子網域對外連線

  tags = local.tags
}

# 至 aws 註冊新的 ssh key
# 假如要使用現有 ssh key，後續步驟請用 key_name 指定，或使用 resource 取代
# 參考指令：
#   ssh 連線: ssh -i ssh_key.pem ec2-user@${ec2_public_dns}
#   初始化 log: cat /var/log/cloud-init-output.log
module "ssh_key" {
  source = "./modules/ssh-key"

  key_name = "${local.name}-ssh-key"
  filename = "./ssh_key.pem"

  tags = local.tags
}

# 建立 ec2，用於執行 ELT
module "ec2" {
  source = "./modules/ec2"

  # 基本設定
  name          = "${local.name}-ec2"
  instance_type = var.ec2_instance_type

  # 網路設定
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0] # subnet 需配置 vpc 的 public subnet，才可從公開 DNS 連線

  # ssh 連線設定
  key_name = module.ssh_key.key_name
  ssh_cidr = var.connect_cidr

  tags = local.tags
}

# 建立 s3 儲存貯體，用於放置 redshift、DMS 資訊
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.1"

  bucket_prefix = "${local.name}-"

  attach_deny_insecure_transport_policy = false
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  force_destroy = true

  tags = local.tags
}

# 建立 redshift
# jdbc 連線字串: jdbc:redshift://${redshift_cluster_endpoint}/dev
module "redshift" {
  source = "./modules/redshift"

  # 基本設定
  name            = "${local.name}-redshift"
  node_type       = var.redshift_node_type
  number_of_nodes = var.redshift_number_of_nodes

  # 網路設定
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.redshift_subnets

  # 資料庫設定
  database_name   = var.redshift_database_name
  master_username = var.redshift_master_username
  master_password = var.redshift_master_password

  # log 存放設定
  s3_bucket_id = module.s3_bucket.s3_bucket_id
}

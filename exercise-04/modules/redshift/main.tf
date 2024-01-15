# 取得 dms 連接使用 iam 角色 (此角色由 dms 建立)
data "aws_iam_role" "dms-access-for-endpoint" {
  name = "dms-access-for-endpoint"
}

# 建立 s3 儲存貯體，用於放置 redshift log
module "redshift_log_s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.1"

  bucket_prefix = "${var.name}-log-"

  attach_deny_insecure_transport_policy = false
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  force_destroy = true

  tags = var.tags
}

# 建立 iam policy，使 redshift 有權讀寫 s3
data "aws_iam_policy_document" "redshift-access-bucket-assume-policy" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "redshift.amazonaws.com"
      ]
    }

    actions = [
      "s3:PutObject",
      "s3:DeleteBucket",
      "s3:GetBucketAcl",
    ]

    # 指定 s3 儲存貯體及底下範圍
    resources = [
      module.redshift_log_s3_bucket.s3_bucket_arn,
      "${module.redshift_log_s3_bucket.s3_bucket_arn}/*",
    ]
  }
}

# 綁定 s3 儲存貯體與 iam policy
resource "aws_s3_bucket_policy" "dms_s3_bucket_redshift_log_policy" {
  bucket = module.redshift_log_s3_bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.redshift-access-bucket-assume-policy.json
}

# 建立 redshift 專用安全群組
resource "aws_security_group" "redshift" {
  description = "default security group for ${var.name}"
  name        = var.name
  vpc_id      = var.vpc_id

  tags = var.tags

  # 開放往內 
  ingress {
    description = "redshfit"
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [var.connect_cidr]
  }

  # 開放往外
  egress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 建立 redshift 
module "redshift" {
  source = "terraform-aws-modules/redshift/aws"

  # 基本設定
  cluster_identifier    = var.name
  allow_version_upgrade = true
  node_type             = var.node_type
  number_of_nodes       = var.number_of_nodes

  # 資料庫設定
  database_name          = var.database_name
  master_username        = var.master_username
  create_random_password = false
  master_password        = var.master_password

  # 加密設定
  encrypted = true

  # 關聯角色綁定
  iam_role_arns = [
    data.aws_iam_role.dms-access-for-endpoint.arn,
  ]

  # 網路與安全性設定
  enhanced_vpc_routing   = true
  vpc_security_group_ids = [aws_security_group.redshift.id]
  subnet_ids             = var.subnet_ids

  availability_zone_relocation_enabled = true
  publicly_accessible                  = true # 是否開放外網讀取

  # log 設定
  logging = {
    enable        = true
    bucket_name   = module.redshift_log_s3_bucket.s3_bucket_id
  }

  # Parameter group
  parameter_group_name        = var.name
  parameter_group_description = "Custom parameter group for ${var.name} cluster"
  parameter_group_parameters = {
    wlm_json_configuration = {
      name = "wlm_json_configuration"
      value = jsonencode([
        {
          query_concurrency = 15
        }
      ])
    }
    require_ssl = {
      name  = "require_ssl"
      value = true
    }
    use_fips_ssl = {
      name  = "use_fips_ssl"
      value = false
    }
    enable_user_activity_logging = {
      name  = "enable_user_activity_logging"
      value = true
    }
    max_concurrency_scaling_clusters = {
      name  = "max_concurrency_scaling_clusters"
      value = 3
    }
    enable_case_sensitive_identifier = {
      name  = "enable_case_sensitive_identifier"
      value = true
    }
  }
  parameter_group_tags = {
    Additional = "CustomParameterGroup"
  }

  # Subnet group
  subnet_group_name        = var.name
  subnet_group_description = "Custom subnet group for ${var.name} cluster"
  subnet_group_tags = {
    Additional = "CustomSubnetGroup"
  }

  # Endpoint access
  create_endpoint_access          = true
  endpoint_name                   = var.name
  endpoint_subnet_group_name      = var.name
  endpoint_vpc_security_group_ids = [aws_security_group.redshift.id]

  # Usage limits
  usage_limits = {
    currency_scaling = {
      feature_type  = "concurrency-scaling"
      limit_type    = "time"
      amount        = 60
      breach_action = "emit-metric"
    }
    spectrum = {
      feature_type  = "spectrum"
      limit_type    = "data-scanned"
      amount        = 2
      breach_action = "disable"
      tags = {
        Additional = "CustomUsageLimits"
      }
    }
  }

  tags = var.tags
}

# 使用 secrets manager 儲存 redshift 連線資訊
module "redshift_secrets_manager" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "~> 1.0"

  name_prefix = "${var.name}-redshift-"
  description = "Redshift secret for ${var.name}"

  # Secret
  recovery_window_in_days = 0
  secret_string = jsonencode(
    {
      host     = module.redshift.endpoint_access_address
      port     = 5439
      username = var.master_username
      password = var.master_password
    }
  )

  tags = var.tags
}

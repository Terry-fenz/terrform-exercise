locals {
  dms_instance_id = "${var.name}-dms-replication"

  # 通知事件類別
  replication_instance_event_categories = ["failure", "creation", "deletion", "maintenance", "failover", "low storage", "configuration change"]
  replication_task_event_categories     = ["failure", "state change", "creation", "deletion", "configuration change"]
}

# 建立 cloudwatch log group
resource "aws_cloudwatch_log_group" "dms_task_log_group" {
  name              = "dms-tasks-${local.dms_instance_id}" # Fixed name for task
  retention_in_days = 60

  tags = var.tags
}

# 建立 s3 bucket
module "dms_s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.1"

  bucket_prefix = "dms-${var.name}-"

  attach_deny_insecure_transport_policy = false
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  force_destroy = true

  # 標籤
  tags = var.tags
}

# 建立 iam policy，使 dms 有權讀寫 s3
data "aws_iam_policy_document" "dms-access-bucket-assume-policy" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "dms.amazonaws.com",
        "redshift.amazonaws.com"
      ]
    }

    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:ListBucketMultipartUploads",

      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObjectVersion",
      "s3:GetBucketPolicy",
      "s3:DeleteBucket",
      "s3:DeleteBucketPolicy",
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]

    # 指定 s3 儲存貯體及底下範圍
    resources = [
      module.dms_s3_bucket.s3_bucket_arn,
      "${module.dms_s3_bucket.s3_bucket_arn}/*",
    ]
  }
}

# 綁定 s3 儲存貯體與 iam policy
resource "aws_s3_bucket_policy" "dms_s3_bucket_dms_policy" {
  bucket = module.dms_s3_bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.dms-access-bucket-assume-policy.json
}

# 建立 DMS 專用安全群組
resource "aws_security_group" "dms" {
  description = "default security group for ${var.name}-dms"
  name        = "${var.name}-dms"
  vpc_id      = var.vpc_id

  # 標籤
  tags = var.tags

  # 開放往外 
  egress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "redshfit"
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "mysql"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 建立 DMS 服務
module "database_migration_service" {
  source  = "terraform-aws-modules/dms/aws"
  version = "~> 2.0"

  # Subnet group
  repl_subnet_group_name        = "${var.name}-dms"
  repl_subnet_group_description = "DMS subnet group for ${var.name}-dms"
  repl_subnet_group_subnet_ids  = var.subnet_ids

  # Instance
  # This value is used when subscribing to instance event notifications
  repl_instance_id                          = local.dms_instance_id
  repl_instance_allocated_storage           = 64
  repl_instance_auto_minor_version_upgrade  = true
  repl_instance_allow_major_version_upgrade = true
  repl_instance_apply_immediately           = true
  repl_instance_engine_version              = "3.5.2"
  repl_instance_multi_az                    = true
  repl_instance_publicly_accessible         = true
  repl_instance_class                       = var.repl_instance_class
  repl_instance_vpc_security_group_ids      = [aws_security_group.dms.id]

  # IAM role
  create_iam_roles = false
  # Access role
  create_access_iam_role = true
  create_access_policy   = true
  access_iam_role_name   = "${var.name}-dms-role"
  access_iam_role_tags   = var.tags
  access_secret_arns = [
    var.mysql_secret_arn,
    var.redshift_secret_arn
  ]

  # Endpoints
  endpoints = {
    mysql-source = {
      endpoint_type       = "source"
      endpoint_id         = "${var.name}-source-live-pp"
      engine_name         = "mysql"
      secrets_manager_arn = var.mysql_secret_arn
      ssl_mode            = "none"

      tags = { EndpointType = "mysql-source" }
    }

    redshift-target = {
      endpoint_type       = "target"
      endpoint_id         = "${var.name}-target-redshift"
      engine_name         = "redshift"
      database_name       = var.redshift_db_name
      secrets_manager_arn = var.redshift_secret_arn
      ssl_mode            = "none"

      redshift_settings = {
        bucket_name = module.dms_s3_bucket.s3_bucket_id
      }

      tags = { EndpointType = "redshift-target" }
    }
  }

  # Task
  replication_tasks = {
    mysql_redshift = {
      replication_task_id       = var.name
      migration_type            = "full-load-and-cdc"
      replication_task_settings = file("${path.module}/configs/task_settings.json") # 請手動移除 CloudWatchLogGroup、CloudWatchLogStream 設定
      table_mappings            = file("${path.module}/configs/table_mappings.json")
      source_endpoint_key       = "mysql-source"
      target_endpoint_key       = "redshift-target"

      tags = { Task = "MySQL-to-Redshift" }
    }
  }

  # 通知
  event_subscriptions = {
    instance = {
      name                             = "instance-events"
      enabled                          = true
      instance_event_subscription_keys = [local.dms_instance_id]
      source_type                      = "replication-instance"
      sns_topic_arn                    = var.sns_topic_arn
      event_categories                 = local.replication_instance_event_categories
    }

    task = {
      name                         = "task-events"
      enabled                      = true
      task_event_subscription_keys = ["mysql_redshift"]
      source_type                  = "replication-task"
      sns_topic_arn                = var.sns_topic_arn
      event_categories             = local.replication_task_event_categories
    }
  }

  # Timeout
  repl_instance_timeouts = {
    create = "2h"
    update = "2h"
    delete = "2h"
  }

  # 標籤
  tags = var.tags

  # 依賴
  depends_on = [
    aws_cloudwatch_log_group.dms_task_log_group # 日誌群組
  ]
}

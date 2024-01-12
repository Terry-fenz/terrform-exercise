data "aws_region" "current" {}
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  dns_suffix = data.aws_partition.current.dns_suffix
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.name
}

data "aws_iam_policy_document" "dms_assume_role" {
  count = var.create_iam_roles ? 1 : 0

  statement {
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]

    principals {
      type = "Service"
      identifiers = [
        "dms.${local.dns_suffix}",
        "dms.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "dms_assume_role_redshift" {
  count = var.create_iam_roles ? 1 : 0

  source_policy_documents = [data.aws_iam_policy_document.dms_assume_role[0].json]

  statement {
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]

    principals {
      type = "Service"
      identifiers = [
        "redshift.${local.dns_suffix}",
        "redshift.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "dms_access_for_endpoint" {
  count = var.create_iam_roles ? 1 : 0

  name                  = "dms-access-for-endpoint"
  description           = "DMS IAM role for endpoint access permissions"
  permissions_boundary  = var.iam_role_permissions_boundary
  assume_role_policy    = data.aws_iam_policy_document.dms_assume_role_redshift[0].json
  managed_policy_arns   = ["arn:${local.partition}:iam::aws:policy/service-role/AmazonDMSRedshiftS3Role"]
  force_detach_policies = true

  tags = var.tags
}

resource "aws_iam_role" "dms_cloudwatch_logs_role" {
  count = var.create_iam_roles ? 1 : 0

  name                  = "dms-cloudwatch-logs-role"
  description           = "DMS IAM role for CloudWatch logs permissions"
  permissions_boundary  = var.iam_role_permissions_boundary
  assume_role_policy    = data.aws_iam_policy_document.dms_assume_role[0].json
  managed_policy_arns   = ["arn:${local.partition}:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"]
  force_detach_policies = true

  tags = var.tags
}

resource "aws_iam_role" "dms_vpc_role" {
  count = var.create_iam_roles ? 1 : 0

  name                  = "dms-vpc-role"
  description           = "DMS IAM role for VPC permissions"
  permissions_boundary  = var.iam_role_permissions_boundary
  assume_role_policy    = data.aws_iam_policy_document.dms_assume_role[0].json
  managed_policy_arns   = ["arn:${local.partition}:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"]
  force_detach_policies = true

  tags = var.tags
}

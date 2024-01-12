locals {
  lambda_file          = "${path.module}/lambda/dms-log-to-sns.zip" # lambda 原始碼位置
  lambda_function_name = "${var.name}-dms-log-to-sns"
}

# 建立 SNS topic
resource "aws_sns_topic" "sns_tpoic" {
  name = "${var.name}-event"

  tags = var.tags
}

# 訂閱 email
resource "aws_sns_topic_subscription" "sns_topic_subscription" {
  for_each = toset(var.subscription_endpoints)

  topic_arn = aws_sns_topic.sns_tpoic.arn
  protocol  = "email"
  endpoint  = each.key
}

# 建立 cloudwatch log group (for lambda function)
resource "aws_cloudwatch_log_group" "lambda_function_log_group" {
  name              = "/aws/lambda/${local.lambda_function_name}" # Fixed name for task
  retention_in_days = 1
  
  tags = var.tags
}

# 建立 role 的信任的實體規則 (for lambda function)
# 實體規則: 在指定條件下可擔任此角色的實體。
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# 建立 role (for lambda function)
resource "aws_iam_role" "iam_for_lambda" {
  name               = "${var.name}-lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = var.tags
}

# 建立 role 的許可政策 (for lambda function)
data "aws_iam_policy_document" "policy" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:Describe*"]
    resources = ["*"]
  }

  # For cloudwatch log
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }

  # For 推送 sns
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = ["arn:aws:sns:*:*:*"]
  }
}

# 建立 role 的權限 policy (for lambda function)
resource "aws_iam_policy" "policy" {
  policy = data.aws_iam_policy_document.policy.json
  tags   = var.tags
}

# 綁定 role 的權限 policy (for lambda function)
resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.policy.arn
}

# 建立 lambda function
resource "aws_lambda_function" "dms-log-to-sns" {
  filename      = local.lambda_file
  function_name = local.lambda_function_name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256(local.lambda_file)

  runtime = "python3.11"

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.sns_tpoic.arn
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.policy_attachment,
    aws_cloudwatch_log_group.lambda_function_log_group,
  ]
}

# 建立 SNS topic
resource "aws_sns_topic" "sns_tpoic" {
  name = "${var.name}-event"
}

# 訂閱 email
resource "aws_sns_topic_subscription" "sns_topic_subscription" {
  for_each = toset(var.subscription_endpoints)

  topic_arn = aws_sns_topic.sns_tpoic.arn
  protocol  = "email"
  endpoint  = each.key
}

# SNS Topic 的 arn
output "arn" {
  description = "SNS topic arn"
  value       = aws_sns_topic.sns_tpoic.arn
}

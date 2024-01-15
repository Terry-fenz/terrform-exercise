# SNS Topic 的 arn
output "sns_topic_arn" {
  description = "SNS topic arn"
  value       = aws_sns_topic.sns_tpoic.arn
}

# Lambda function 的名稱
output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.dms_log_to_sns.function_name
}

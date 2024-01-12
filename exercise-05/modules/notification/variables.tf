# SNS 的名稱
variable "name" {
  description = "SNS name"
  type        = string
}

# DMS 叢集所屬子網域列表
variable "subscription_endpoints" {
  description = "SNS subscription endpoints"
  type        = list(string)
}

# SNS tags
variable "tags" {
  description = "SNS tags"
  type        = map(string)
  default     = {}
}
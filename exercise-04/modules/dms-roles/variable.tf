variable "create_iam_roles" {
  description = "Determines whether the required [DMS IAM resources](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.html#CHAP_Security.APIRole) will be created"
  type        = bool
}

variable "iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the role"
  type        = string
  default     = null
}

variable "tags" {
  description = "DMS tags"
  type        = map(string)
  default     = {}
}
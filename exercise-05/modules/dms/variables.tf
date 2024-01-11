# DMS 的執行個體名稱
variable "name" {
  description = "DMS instance name"
  type        = string
}

# DMS 叢集所屬 VPC ID
variable "vpc_id" {
  description = "VPC id for DMS"
  type        = string
}

# DMS 叢集所屬子網域列表
variable "subnet_ids" {
  description = "Subnet id list for DMS"
  type        = list(string)
}

# DMS 複寫執行個體類別
variable "repl_instance_class" {
  description = "Replication instance class for DMS"
  type        = string
}

# mysql 來源端點帳密 arn
variable "mysql_secret_arn" {
  description = "AWS secret arn for mysql source endpoint"
  type        = string
}

# redshift 目標端點帳密 arn
variable "redshift_secret_arn" {
  description = "AWS secret arn for redshift target endpoint"
  type        = string
}

# redshift 目標端點資料庫名稱
variable "redshift_db_name" {
  description = "Database name for redshift target endpoint"
  type        = string
}

# DMS tags
variable "tags" {
  description = "DMS tags"
  type        = map(string)
  default     = {}
}

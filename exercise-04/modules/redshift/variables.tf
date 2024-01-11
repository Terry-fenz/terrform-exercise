# Redshift 叢集的名稱
variable "name" {
  description = "Redshift cluster name"
  type        = string
}

# Redshift 叢集所屬 VPC ID
variable "vpc_id" {
  description = "VPC id for redshift cluster"
  type        = string
}

# Redshift 叢集所屬子網域列表
variable "subnet_ids" {
  description = "Subnet id list for redshift cluster"
  type        = list(string)
}

# Redshift 的節點類型
variable "node_type" {
  description = "Redshift node type"
  type        = string
}

# Redshift 的節點數量
variable "number_of_nodes" {
  description = "Redshift nodes number"
  type        = number
}

# Redshift 的預設資料庫名稱
variable "database_name" {
  description = "Redshift database name"
  type        = string
  sensitive   = true # 敏感資訊
}

# Redshift 的預設帳號名稱
variable "master_username" {
  description = "Redshift master username"
  type        = string
  sensitive   = true # 敏感資訊
}

# Redshift 的預設帳號密碼
variable "master_password" {
  description = "Redshift master password"
  type        = string
  sensitive   = true # 敏感資訊
}

# 開放連線的 cidr block
variable "connect_cidr" {
  type        = string
  description = "cidr block for connect redshift"
}

# Redshift tags
variable "tags" {
  description = "Redshift tags"
  type        = map(string)
  default     = {}
}

# aws region
variable "region" {
  description = "aws region"
  type        = string
  default     = "ap-southeast-1" # 新加坡
}

# 開放連線的 cidr block
variable "connect_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "cidr block for ssh ec2、connect redshift"
}

# ec2 的執行個體類型
variable "ec2_instance_type" {
  description = "ec2 instance type"
  type        = string
  default     = "t2.micro"
}

# Redshift 的節點類型
variable "redshift_node_type" {
  description = "Redshift node type"
  type        = string
  default     = "ra3.xlplus"
}

# Redshift 的節點數量
variable "redshift_number_of_nodes" {
  description = "Redshift nodes number"
  type        = number
  default     = 1
}

# Redshift 的預設資料庫名稱
variable "redshift_database_name" {
  description = "Redshift database name"
  type        = string
  default     = "dev"
  sensitive   = true # 敏感資訊
}

# Redshift 的預設帳號名稱
variable "redshift_master_username" {
  description = "Redshift master username"
  type        = string
  default     = "awsuser111"
  sensitive   = true # 敏感資訊
}

# Redshift 的預設帳號密碼
variable "redshift_master_password" {
  description = "Redshift master password"
  type        = string
  default     = "Awsuser111Awsuser111Awsuser111!"
  sensitive   = true # 敏感資訊
}

# 是否建立 DMS 所需基本 IAM 角色
variable "dms_create_iam_roles" {
  description = "Determines whether the required [DMS IAM resources](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.html#CHAP_Security.APIRole) will be created"
  type        = bool
  default     = false
}

# DMS 複寫執行個體類別
variable "dms_repl_instance_class" {
  description = "Replication instance class for DMS"
  type        = string
  default     = "dms.t3.large"
}

# DMS 資料來源(mysql)資訊的 secret arn
variable "dms_mysql_secret_arn" {
  description = "Secret arn for dms mysql source"
  type        = string
  default     = "arn:aws:secretsmanager:ap-southeast-1:380713445581:secret:data-center-mysql-source-example-yZnstp" # test case
  sensitive   = true                                                                                                # 敏感資訊
}

# 告警、通知的郵件對象
variable "notification_mails" {
  description = "Notification target by email"
  type        = list(string)
  default     = ["terry-tw@fenz.vip"]
}

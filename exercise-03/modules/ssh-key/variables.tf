# SSH key 名稱
variable "key_name" {
  description = "SSH key name"
  type        = string
  default     = "ssh-key"
}

# SSH key 加密演算法
variable "algorithm" {
  description = "Name of the algorithm to use when generating the private key"
  type        = string
  default     = "RSA"
}

# SSH key 加密參數 (only for RSA)
variable "rsa_bits" {
  description = "When algorithm is RSA, the size of the generated RSA key, in bits "
  type        = number
  default     = 4096
}

# SSH key 輸出檔案名稱
variable "filename" {
  description = "SSH key file name"
  type        = string
  default     = "ssh_key.pem"
}

# SSH key tags
variable "tags" {
  description = "SSH key tags"
  type        = map(string)
  default     = {}
}

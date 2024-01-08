# 取得 ec2 使用映象檔
# 查詢指令：aws ec2 describe-images --region ap-southeast-1 --filters "Name=name, Values=al2023-ami-2023*x86_64*" |grep \"Name
data "aws_ami" "amazon_linux_2023_ami" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023*x86_64*"]
  }
}

# 建立一個 ec2
resource "aws_instance" "ec2" {
  instance_type = var.instance_type
  ami           = data.aws_ami.amazon_linux_2023_ami.id
  key_name      = var.key_name

  vpc_security_group_ids      = ["${aws_security_group.ec2.id}"] # 請使用 vpc_security_group_ids，而不是 security_group，否則會每次執行時都重建 aws_instance
  associate_public_ip_address = true                             # 開放公開 DNS，用於 ssh 連線

  subnet_id = var.subnet_id # subnet 需配置 vpc 的 public subnet，才可從公開 DNS 連線

  user_data = file("${path.module}/script/init_docker.sh") # show log in ec2: /var/log/cloud-init-output.log

  tags = merge({
    "Name" : var.name
  }, var.tags)
}

# 建立 ec2 專用安全群組
resource "aws_security_group" "ec2" {
  description = "default security group for ${var.name}"
  name        = var.name
  vpc_id      = var.vpc_id

  tags = var.tags

  # 開放往內 ssh
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr] # 使用 variable 輸入，預設全開放
  }

  # 開放往外 http、https (下載套件、更新用)
  egress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 開放往外呼叫 harbor
  # TODO: Change for production
  egress {
    description = "harbor"
    from_port   = 8070
    to_port     = 8070
    protocol    = "tcp"
    cidr_blocks = ["54.251.6.240/32"]
  }
}

#!/bin/bash
whoami # show current user

# 安裝 docker
dnf update
dnf install docker -y
systemctl start docker
systemctl enable docker
systemctl status docker

# 調整 docker 權限給 ec2-user
usermod -aG docker ec2-user
mkdir /home/ec2-user/.docker
chown ec2-user:ec2-user /home/ec2-user/.docker -R
chmod g+rwx "/home/ec2-user/.docker" -R
docker --version

# 安裝 docker-compose
curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose version

# ======================================
# TODO: Change for production
# For demo harbor login
echo "{
  \"insecure-registries\": [
    \"http://54.251.6.240:8070\"
  ],
  \"registry-mirrors\":[
    \"http://54.251.6.240:8070\"
  ]
}" > /etc/docker/daemon.json

systemctl restart docker
docker login -u admin -p Harbor12345 http://54.251.6.240:8070

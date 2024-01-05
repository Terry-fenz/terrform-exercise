#!/bin/bash

# 安裝 docker
sudo dnf update
sudo dnf install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl status docker

# 調整 docker 權限
sudo usermod -aG docker ec2-user
newgrp docker
sudo chmod g+rwx "$HOME/.docker" -R
docker --version

# 安裝 docker-compose
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose version

# ======================================
# TODO: Change for production
# For demo harbor login
sudo echo "{
  \"insecure-registries\": [
    \"http://54.251.6.240:8070\"
  ],
  \"registry-mirrors\":[
    \"http://54.251.6.240:8070\"
  ]
}" > /etc/docker/daemon.json

sudo systemctl restart docker
docker login -u admin -p Harbor12345 http://54.251.6.240:8070

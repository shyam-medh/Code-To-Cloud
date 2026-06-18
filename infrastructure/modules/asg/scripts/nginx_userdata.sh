#!/bin/bash
yum update -y
yum install -y docker git
systemctl start docker
systemctl enable docker

# Clone the repository
git clone https://github.com/shyam-medh/Code-To-Cloud.git /app

# Build and run the Nginx reverse proxy
cd /app/infrastructure/docker/nginx
docker build -t nginx-proxy .
docker run -d -p 80:80 -e INTERNAL_NLB_DNS="${internal_nlb_dns}" nginx-proxy

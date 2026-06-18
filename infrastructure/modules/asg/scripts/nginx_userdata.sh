#!/bin/bash
apt-get update -y
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

# Jenkins builds and pushes to Docker Hub.
# We just pull and run it!
docker pull shyammedh/nginx-proxy:latest
docker run -d -p 80:80 -e INTERNAL_NLB_DNS="${internal_nlb_dns}" shyammedh/nginx-proxy:latest

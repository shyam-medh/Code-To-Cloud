#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker

# The actual Jenkins pipeline will build the image and push to Docker Hub.
# The ASG pulls the latest image instead of building from source!
docker pull yourdockerhubusername/java-app:latest
docker run -d -p 8081:8081 yourdockerhubusername/java-app:latest

#!/bin/bash
apt-get update -y
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

# The actual Jenkins pipeline will build the image and push to Docker Hub.
# The ASG pulls the latest image instead of building from source!
docker pull shyammedh/java-app:latest
docker run -d -p 8081:8081 shyammedh/java-app:latest

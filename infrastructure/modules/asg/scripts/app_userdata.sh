#!/bin/bash
yum update -y
yum install -y docker git
systemctl start docker
systemctl enable docker

# Clone the repository
git clone https://github.com/shyam-medh/Code-To-Cloud.git /app

# Build and run the Java Application
cd /app/task-tracker
docker build -t java-app .
docker run -d -p 8081:8081 java-app

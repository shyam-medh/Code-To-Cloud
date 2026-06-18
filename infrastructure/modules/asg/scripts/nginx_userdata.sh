#!/bin/bash
apt-get update -y
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

# Create the Nginx configuration file dynamically
cat << 'EOCONF' > /home/ubuntu/default.conf
server {
    listen 80;
    location / {
        proxy_pass http://${internal_nlb_dns}:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOCONF

# Run the official Nginx docker image and mount the config file
docker pull nginx:latest
docker run -d -p 80:80 -v /home/ubuntu/default.conf:/etc/nginx/conf.d/default.conf:ro nginx:latest

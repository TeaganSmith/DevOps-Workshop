#!/bin/bash

# System Update & Core Packages
apt-get update -y
apt-get upgrade -y
apt-get install -y python3 python3-pip git nginx
snap install terraform --classic

# Install Flask
pip3 install flask dotenv

# Clone your app
cd /home/ubuntu
git clone https://github.com/TODO/DevOps-Workshop.git
chown -R ubuntu:ubuntu DevOps-Workshop

# Create systemd service for Flask
cat <<EOF > /etc/systemd/system/flask-app.service
[Unit]
Description=Flask SaaS App
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/DevOps-Workshop
ExecStart=/usr/bin/python3 /home/ubuntu/DevOps-Workshop/app.py
Restart=always
Environment="PYTHONUNBUFFERED=1"

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Flask service
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable flask-app
systemctl start flask-app

# Configure NGINX to reverse proxy to Flask
cat <<EOF > /etc/nginx/sites-available/flask
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
    }
}
EOF

ln -sf /etc/nginx/sites-available/flask /etc/nginx/sites-enabled/flask
rm -f /etc/nginx/sites-enabled/default
sudo systemctl reload nginx
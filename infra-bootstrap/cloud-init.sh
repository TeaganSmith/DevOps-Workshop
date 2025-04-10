#!/bin/bash

# Update and install packages
apt-get update -y
apt-get upgrade -y
apt-get install -y curl wget apt-transport-https ca-certificates gnupg lsb-release docker.io conntrack

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube

# Add user to docker group
usermod -aG docker ubuntu

# Start Minikube (will run as root initially — user may need to interact after reboot)
minikube start --driver=none > /var/log/minikube-start.log 2>&1

mkdir -p /home/ubuntu/.kube
cp -i /root/.kube/config /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube
# Clone your repo (replace with your actual repo URL)
cd /home/ubuntu
git clone https://github.com/TeaganSmith/DevOps-Workshop.git
chown -R ubuntu:ubuntu DevOps-Workshop

# Optional: deploy initial service
#su - ubuntu -c "cd ~/DevOps-Workshop/saas-provisioner && kubectl apply -f deployment.yaml && kubectl apply -f service.yaml"
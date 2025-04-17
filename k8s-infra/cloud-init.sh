#!/bin/bash
set -euxo pipefail

# System updates and essential tools
apt-get update -y
apt-get upgrade -y
apt-get install -y curl apt-transport-https ca-certificates gnupg lsb-release docker.io conntrack socat jq git make gcc g++ golang-go

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Install Terraform (latest via snap)
snap install terraform --classic

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install -o root -g root -m 0755 minikube-linux-amd64 /usr/local/bin/minikube

# Install crictl
CRICTL_VERSION="v1.29.0"
curl -LO https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
tar -C /usr/local/bin -xzf crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
rm crictl-${CRICTL_VERSION}-linux-amd64.tar.gz

# Install cri-dockerd
git clone https://github.com/Mirantis/cri-dockerd.git /opt/cri-dockerd
cd /opt/cri-dockerd
mkdir -p bin
go mod init github.com/Mirantis/cri-dockerd || true  # fallback if not already initialized
go mod tidy
go build -o bin/cri-dockerd

install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd

# Setup systemd service
cp -a packaging/systemd/* /etc/systemd/system
sed -i 's:/usr/bin/cri-dockerd:/usr/local/bin/cri-dockerd:' /etc/systemd/system/cri-docker.service
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now cri-docker.socket

# Start Minikube
minikube start --driver=none --container-runtime=docker --cri-socket=unix:///var/run/cri-dockerd.sock

# Deploy sample app
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: kuard
spec:
  containers:
  - name: kuard
    image: gcr.io/kuar-demo/kuard-amd64:blue
    ports:
    - containerPort: 8080
EOF

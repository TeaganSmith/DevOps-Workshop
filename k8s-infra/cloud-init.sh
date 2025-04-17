#!/bin/bash
set -euxo pipefail

# Update system and install essentials
apt-get update -y
apt-get upgrade -y
apt-get install -y curl apt-transport-https ca-certificates gnupg lsb-release software-properties-common docker.io conntrack socat jq git make gcc g++ golang-go

# Enable Docker
systemctl enable docker
systemctl start docker

# Install Terraform via Snap
snap install terraform --classic

# Install kubectl
KUBECTL_VERSION=$(curl -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install -o root -g root -m 0755 minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

# Install crictl
CRICTL_VERSION="v1.29.0"
curl -LO https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
tar -C /usr/local/bin -xzf crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
rm crictl-${CRICTL_VERSION}-linux-amd64.tar.gz

# Install cri-dockerd
git clone https://github.com/Mirantis/cri-dockerd.git /opt/cri-dockerd
cd /opt/cri-dockerd
go mod tidy || true
go build -o bin/cri-dockerd
install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd

# Set up cri-dockerd as a service
cp -a packaging/systemd/* /etc/systemd/system
sed -i 's:/usr/bin/cri-dockerd:/usr/local/bin/cri-dockerd:' /etc/systemd/system/cri-docker.service
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now cri-docker.socket

# Start Minikube
minikube start --driver=none --container-runtime=docker --cri-socket=unix:///var/run/cri-dockerd.sock

# Deploy sample app (KUARD)
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

#!/bin/bash
swapoff -a
apt-get update -y
apt-get install -y curl apt-transport-https docker.io conntrack jq

cat <<EOF | tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

systemctl daemon-reexec
systemctl enable docker
systemctl restart docker

# Install Minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube /usr/local/bin/

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install kubectl /usr/local/bin/

# Setup as ubuntu user
su - ubuntu <<'EOF'
minikube start --driver=none --cpus=2 --memory=4096

# Deploy kuard
kubectl create deployment kuard --image=gcr.io/kuar-demo/kuard-amd64:blue

# Expose kuard via NodePort
kubectl expose deployment kuard --type=NodePort --port=8080

EOF

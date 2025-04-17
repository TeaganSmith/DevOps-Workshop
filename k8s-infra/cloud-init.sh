#!/bin/bash
set -euxo pipefail
exec > /var/log/cloud-init-output.log 2>&1    # everything goes to the log

###############################################################################
# 1.  OS packages & Docker
###############################################################################
apt-get update -y
apt-get upgrade -y
apt-get install -y \
  curl ca-certificates gnupg lsb-release software-properties-common \
  docker.io conntrack socat jq git make gcc g++ golang-go

systemctl enable --now docker

###############################################################################
# 2.  Terraform   (snap is fine)
###############################################################################
snap install terraform --classic
command -v terraform >/dev/null       # abort if missing

###############################################################################
# 3.  kubectl     (official apt repo – avoids 404 problems)
###############################################################################
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | \
      gpg --dearmor -o /usr/share/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] \
      https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" \
      >/etc/apt/sources.list.d/kubernetes.list
apt-get update -y
apt-get install -y kubectl
command -v kubectl >/dev/null

###############################################################################
# 4.  Minikube   (official .deb package)
###############################################################################
curl -fsSL https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb \
     -o /tmp/minikube.deb
dpkg -i /tmp/minikube.deb
rm /tmp/minikube.deb
command -v minikube >/dev/null

###############################################################################
# 5.  crictl
###############################################################################
CRICTL_VERSION="v1.29.0"
curl -fsSL https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz \
 | tar -C /usr/local/bin -xz --strip-components=1
command -v crictl >/dev/null

###############################################################################
# 6.  cri‑dockerd
###############################################################################
git clone --depth=1 https://github.com/Mirantis/cri-dockerd.git /opt/cri-dockerd
cd /opt/cri-dockerd
go build -o cri-dockerd
install -o root -g root -m 0755 cri-dockerd /usr/local/bin/cri-dockerd

cp -a packaging/systemd/* /etc/systemd/system
sed -i 's:/usr/bin/cri-dockerd:/usr/local/bin/cri-dockerd:' /etc/systemd/system/cri-docker.service
systemctl daemon-reload
systemctl enable --now cri-docker.socket
command -v cri-dockerd >/dev/null

###############################################################################
# 7.  Start Minikube (none driver + Docker runtime)
###############################################################################
minikube start --driver=none \
               --container-runtime=docker \
               --cri-socket=unix:///var/run/cri-dockerd.sock

###############################################################################
# 8.  Deploy KUARD demo app
###############################################################################
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
echo "✅ setup finished"

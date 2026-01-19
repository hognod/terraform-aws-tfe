#! /bin/bash

until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

# aws cli install
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# kubectl install
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# helm install
wget https://get.helm.sh/helm-v4.0.4-linux-amd64.tar.gz
tar -zxvf helm-v4.0.4-linux-amd64.tar.gz
sudo cp linux-amd64/helm /usr/local/bin

# Docker install
mkdir -p ~/docker-installer
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo sed -i 's/\$releasever/37/g' /etc/yum.repos.d/docker-ce.repo
sudo dnf update
sudo dnf download -y --resolve --alldeps docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin --destdir ~/docker-installer
sudo dnf install --skip-broken --disablerepo="*" --nogpgcheck -y ~/docker-installer/*.rpm
sudo systemctl start docker
sudo systemctl enable docker
sudo chmod 666 /var/run/docker.sock
sudo usermod -aG docker ${USER}

# AWS Load Balancer Controller Image
docker pull public.ecr.aws/eks/aws-load-balancer-controller:v2.17.1
docker save -o ~/aws-load-balancer-controller.tar public.ecr.aws/eks/aws-load-balancer-controller:v2.17.1

# Terraform Enterprise Image
cat ~/terraform.hclic |  docker login --username terraform images.releases.hashicorp.com --password-stdin
docker pull images.releases.hashicorp.com/hashicorp/terraform-enterprise:v202507-1
docker save -o ~/terraform-enterprise.tar images.releases.hashicorp.com/hashicorp/terraform-enterprise:v202507-1

# TFE Agent Image
mkdir -p ~/tfc-agent
docker pull hashicorp/tfc-agent:latest
cat > ~/tfc-agent/Dockerfile << EOF
FROM hashicorp/tfc-agent:latest

# Switch the to root user in order to perform privileged actions such as
# installing software.
USER root

# Install sudo. The container runs as a non-root user, but people may rely on
RUN apt-get -y install sudo
# Permit tfc-agent to use sudo apt-get commands.
RUN echo 'tfc-agent ALL=NOPASSWD: /usr/bin/apt-get , /usr/bin/apt' >> /etc/sudoers.d/50-tfc-agent

# the ability to apt-get install things.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends unzip curl ca-certificates ansible jq python3-pip && wget -qO awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip && unzip awscliv2.zip && ./aws/install && rm -rf ./aws && rm -rf /var/lib/apt/lists/*

# Switch back to the tfc-agent user as needed by Terraform agents.
USER tfc-agent
EOF
docker build --no-cache -t hashicorp/tfc-agent:v1 ~/tfc-agent
docker save -o ~/tfc-agent.tar hashicorp/tfc-agent:v1

# Bundle nginx Image
mkdir -p ~/nginx-bundle
mv ~/nginx.conf ~/nginx-bundle
docker pull nginx:alpine

# AWS Load Balancer Controller Helm Chart
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
helm pull eks/aws-load-balancer-controller

# Terraform Enterprise Helm Chart
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update hashicorp
helm pull hashicorp/terraform-enterprise

# GitLab Installer
mkdir -p ~/gitlab-installer
curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh | sudo bash
sudo dnf download -y --resolve --alldeps gitlab-ce --destdir ~/gitlab-installer
#! /bin/bash

until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

# aws cli install
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# kubectl install
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# helm install
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4

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


# GitLab Installer
mkdir -p ~/gitlab-installer
curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
sudo dnf download -y --resolve --alldeps gitlab-ce --destdir ~/gitlab-installer
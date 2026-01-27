#! /bin/bash

until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

# aws cli install
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# kubectl install
curl -sLO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# helm install
wget -q https://get.helm.sh/helm-v4.0.4-linux-amd64.tar.gz
tar -zxf helm-v4.0.4-linux-amd64.tar.gz
sudo cp linux-amd64/helm /usr/local/bin

# Docker install
mkdir -p ~/docker-installer
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo sed -i 's/\$releasever/37/g' /etc/yum.repos.d/docker-ce.repo
sudo dnf update -q -y
sudo dnf download -q -y --resolve --alldeps docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin --destdir ~/docker-installer
sudo dnf install --skip-broken --disablerepo="*" --nogpgcheck -qq -y ~/docker-installer/*.rpm
sudo systemctl start docker
sudo systemctl enable docker
sudo chmod 666 /var/run/docker.sock
sudo usermod -aG docker ${USER}

# AWS Load Balancer Controller Image
docker pull -q public.ecr.aws/eks/aws-load-balancer-controller:v2.17.1
docker save -o ~/aws-load-balancer-controller.tar public.ecr.aws/eks/aws-load-balancer-controller:v2.17.1

# Terraform Enterprise Image
cat ~/terraform.hclic |  docker login --username terraform images.releases.hashicorp.com --password-stdin
docker pull -q images.releases.hashicorp.com/hashicorp/terraform-enterprise:v202507-1
docker save -o ~/terraform-enterprise.tar images.releases.hashicorp.com/hashicorp/terraform-enterprise:v202507-1

# TFE Agent Image
mkdir -p ~/tfc-agent
docker pull -q hashicorp/tfc-agent:latest
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
docker build -q --no-cache -t hashicorp/tfc-agent:v1 ~/tfc-agent
docker save -o ~/tfc-agent.tar hashicorp/tfc-agent:v1

# Bundle
sudo dnf install -qq -y git
wget -q https://go.dev/dl/go1.25.3.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf ~/go1.25.3.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
sudo ln -s /usr/local/go/bin/go /usr/bin/go
git clone -q --single-branch --branch=v0.15 --depth=1 https://github.com/hashicorp/terraform.git
cd ~/terraform/tools/terraform-bundle && go build -o ~/terraform-bundle . && cd ~/
~/terraform-bundle package ~/terraform-bundle.hcl
mv ~/terraform_*.zip ~/bundle.zip

# Bundle nginx Image
mkdir -p ~/nginx-bundle
mv ~/nginx.conf ~/nginx-bundle
mv ~/bundle.zip ~/nginx-bundle
docker pull -q nginx:alpine
cat > ~/nginx-bundle/Dockerfile << EOF
FROM nginx:alpine

COPY bundle.zip /usr/share/nginx/html/providers/bundle.zip
COPY nginx.conf /etc/nginx/nginx.conf
RUN chmod -R 755 /usr/share/nginx/html/providers

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/providers/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
EOF
docker build -q --no-cache -t nginx:bundle ~/nginx-bundle
docker save -o ~/nginx-bundle.tar nginx:bundle

# AWS Load Balancer Controller Helm Chart
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
helm pull eks/aws-load-balancer-controller --destination ~/

# Terraform Enterprise Helm Chart
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update hashicorp
helm pull hashicorp/terraform-enterprise --destination ~/

# GitLab Installer
mkdir -p ~/gitlab-installer
curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh | sudo bash
sudo dnf download -q -y --resolve --alldeps gitlab-ce --destdir ~/gitlab-installer
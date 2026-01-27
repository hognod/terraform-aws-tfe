#! /bin/bash

until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

# aws cli install
unzip -q ~/awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# kubectl install
sudo install -o root -g root -m 0755 ~/kubectl /usr/local/bin/kubectl
echo 'alias k="kubectl"' >> ~/.bashrc
rm -rf ~/kubectl

# Docker install
sudo dnf install --skip-broken --disablerepo="*" --nogpgcheck -qq -y ~/docker-installer/*.rpm
sudo systemctl start docker
sudo systemctl enable docker
sudo chmod 666 /var/run/docker.sock
sudo usermod -aG docker ${USER}
rm -rf ~/docker-installer

# helm install
sudo mv ~/helm /usr/local/bin
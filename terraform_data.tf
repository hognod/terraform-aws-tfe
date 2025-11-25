resource "terraform_data" "public" {
  connection {
    host        = aws_instance.public.public_ip
    user        = var.os_user
    private_key = tls_private_key.main.private_key_pem

    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      # aws cli install
      "curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o \"awscliv2.zip\"",
      "sudo apt install -y unzip",
      "unzip awscliv2.zip",
      "sudo ./aws/install",
      "aws configure set aws_access_key_id ${var.access_key}",
      "aws configure set aws_secret_access_key ${var.secret_key}",
      "aws configure set region ap-northeast-2",
      # kubectl install
      "curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\"",
      "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
      # helm install
      "curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4",
      "chmod 700 get_helm.sh",
      "./get_helm.sh",

      "echo alias k=\"kubectl\""
    ]
  }
}
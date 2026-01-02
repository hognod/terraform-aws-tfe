resource "terraform_data" "bastion" {
  depends_on = [
    aws_eks_node_group.main
  ]

  connection {
    host        = aws_instance.bastion.public_ip
    user        = var.instance_user
    private_key = tls_private_key.main.private_key_pem

    timeout = "2m"
  }

  provisioner "file" {
    source      = "./cert"
    destination = "/home/${var.instance_user}"
  }

  provisioner "file" {
    content     = tls_private_key.main.private_key_pem
    destination = "/home/${var.instance_user}/${var.prefix}.pem"
  }

  provisioner "file" {
    content     = var.tfe_license
    destination = "/home/${var.instance_user}/terraform.hclic"
  }

  provisioner "file" {
    content     = yamlencode(local.tfe_yaml)
    destination = "/home/${var.instance_user}/terraform.yaml"
  }

  provisioner "file" {
    content     = yamlencode(local.tfe_agent_service_account_yaml)
    destination = "/home/${var.instance_user}/terraform-agent-sa.yaml"
  }

  provisioner "remote-exec" {
    #on_failure = continue

    inline = [
      # prerequisites
      "chmod 400 ~/${var.prefix}.pem",

      # aws cli install
      "curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o \"awscliv2.zip\"",
      "sudo apt install -y unzip",
      "unzip awscliv2.zip",
      "sudo ./aws/install",
      "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.main.name}",

      # kubectl install
      "curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\"",
      "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
      "echo 'alias k=\"kubectl\"' >> ~/.bashrc",

      # helm install
      "curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4",
      "chmod 700 get_helm.sh",
      "./get_helm.sh",

      # TFE Settings
      "kubectl create namespace ${var.tfe_kube_namespace}",

      # # Secrets
      # "kubectl create secret docker-registry terraform-enterprise --namespace ${var.tfe_kube_namespace} --docker-server=images.releases.hashicorp.com --docker-username=terraform --docker-password=${var.tfe_license}",
      # "kubectl create secret generic tfe-secrets --namespace=${var.tfe_kube_namespace} --from-file=TFE_LICENSE=$(pwd)/terraform.hclic --from-literal=TFE_ENCRYPTION_PASSWORD=hashicorp --from-literal=TFE_DATABASE_PASSWORD=${var.db_password}",
      # "kubectl create secret tls tfe-certs --namespace=${var.tfe_kube_namespace} --cert=$(pwd)/cert/cert.pem --key=$(pwd)/cert/key.pem",

      # # AWS Load Balancer Controller deployment
      # "helm repo add eks https://aws.github.io/eks-charts",
      # "helm repo update eks",
      # "timeout 60 helm install aws-load-balancer-controller eks/aws-load-balancer-controller --namespace ${var.tfe_lb_controller_kube_namespace} --set clusterName=${aws_eks_cluster.main.name} --set serviceAccount.create=true --set serviceAccount.name=${var.tfe_lb_controller_kube_svc_account} --set serviceAccount.annotations.\"eks\\.amazonaws\\.com/role-arn\"=${aws_iam_role.lb_controller_irsa_role.arn} --set region=${var.region} --set vpcId=${aws_vpc.main.id} || exit 0",
      # "sleep 60s",

      # # Terraform Enterprise deployment
      # "helm repo add hashicorp https://helm.releases.hashicorp.com",
      # "timeout 180 helm install terraform-enterprise hashicorp/terraform-enterprise --namespace ${var.tfe_kube_namespace} --values terraform.yaml || exit 0",
      # "sleep 180s",

      # # TFE Agent Service Account
      # "kubectl create --namespace ${var.tfe_kube_namespace}-agents -f terraform-agent-sa.yaml",

      # GitLab Installer
      "mkdir -p ~/gitlab-installer",
      "curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash",
      "sudo apt-get install -y --download-only gitlab-ce=18.4.5-ce.0",
      "sudo mv /var/cache/apt/archives/*.deb ~/gitlab-installer",
      "scp -i ~/${var.prefix}.pem -r ~/gitlab-installer ${var.instance_user}@${aws_instance.gitlab.private_ip}:"
    ]
  }
}

# resource "terraform_data" "destroy" {
#   depends_on = [
#     aws_eks_node_group.main,
#     aws_eks_access_entry.bastion,
#     aws_eks_access_policy_association.bastion
#   ]

#   input = {
#     tfe_kube_namespace               = var.tfe_kube_namespace
#     tfe_lb_controller_kube_namespace = var.tfe_lb_controller_kube_namespace
#     host                             = aws_instance.bastion.public_ip
#     user                             = var.instance_user
#     private_key                      = tls_private_key.main.private_key_pem
#   }

#   connection {
#     host        = self.output.host
#     user        = self.output.user
#     private_key = self.output.private_key

#     timeout = "2m"
#   }

#   provisioner "remote-exec" {
#     when       = destroy
#     on_failure = continue
#     inline = [
#       "helm delete terraform-enterprise --namespace ${self.output.tfe_kube_namespace}",
#       "sleep 30s",
#       "helm delete aws-load-balancer-controller --namespace ${self.output.tfe_lb_controller_kube_namespace}",
#       "sleep 30s"
#     ]
#   }
# }


data "template_file" "gitlab" {
  template = file("${path.module}/gitlab.rb.tpl")

  vars = {
    gitlab_domain = var.gitlab_domain
    cert_path     = "/home/${var.instance_user}/cert/service.crt"
    key_path      = "/home/${var.instance_user}/cert/service.key"
  }
}

resource "terraform_data" "gitlab" {
  depends_on = [
    terraform_data.bastion
  ]

  connection {
    bastion_host        = aws_instance.bastion.public_ip
    bastion_user        = var.instance_user
    bastion_private_key = tls_private_key.main.private_key_pem

    host        = aws_instance.gitlab.private_ip
    user        = var.instance_user
    private_key = tls_private_key.main.private_key_pem

    timeout = "2m"
  }

  provisioner "file" {
    source      = "./cert"
    destination = "/home/${var.instance_user}"
  }

  provisioner "file" {
    content     = data.template_file.gitlab.rendered
    destination = "/home/${var.instance_user}/gitlab.rb"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp ~/cert/ca.crt /usr/local/share/ca-certificates",
      "sudo update-ca-certificates",

      "echo 'export LANG=en_US.UTF-8' >> ~/.bashrc",
      "sudo dpkg -i ~/gitlab-installer/*.deb",
      "sudo mv ~/gitlab.rb /etc/gitlab/gitlab.rb",
      "sudo mkdir /etc/gitlab/trusted-certs",
      "sudo cp ~/cert/ca.crt /etc/gitlab/trusted-certs",
      "sudo gitlab-ctl reconfigure"
    ]
  }
}
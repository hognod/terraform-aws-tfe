resource "terraform_data" "public_bastion" {
  depends_on = [
    aws_eks_node_group.main
  ]

  connection {
    host        = aws_instance.public_bastion.public_ip
    user        = var.instance_user
    private_key = tls_private_key.main.private_key_pem

    timeout = "2m"
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
    source      = "${path.module}/config/nginx.conf"
    destination = "/home/${var.instance_user}/nginx.conf"
  }

  provisioner "file" {
    source      = "${path.module}/config/terraform-bundle.hcl"
    destination = "/home/${var.instance_user}/terraform-bundle.hcl"
  }

  provisioner "remote-exec" {
    script = "./scripts/public.sh"
  }

  provisioner "remote-exec" {
    #on_failure = continue

    inline = [
      # # prerequisites
      "chmod 400 ~/${var.prefix}.pem",

      # # Terraform Enterprise deployment
      # "helm install terraform-enterprise hashicorp/terraform-enterprise --namespace ${var.tfe_kube_namespace} --values terraform.yaml || exit 0",
      # "sleep 180s",

      # # TFE Agent Service Account
      # "kubectl create --namespace ${var.tfe_kube_namespace}-agents -f terraform-agent-sa.yaml",

      "scp -q -o StrictHostKeyChecking=no -i ~/${var.prefix}.pem ~/awscliv2.zip ${var.instance_user}@${aws_instance.private_bastion.private_ip}:",
      "scp -q -o StrictHostKeyChecking=no -i ~/${var.prefix}.pem ~/kubectl ${var.instance_user}@${aws_instance.private_bastion.private_ip}:",
      "scp -q -o StrictHostKeyChecking=no -i ~/${var.prefix}.pem -r ~/docker-installer ${var.instance_user}@${aws_instance.private_bastion.private_ip}:",
      "scp -q -o StrictHostKeyChecking=no -i ~/${var.prefix}.pem ~/aws-load-balancer-controller.tar ${var.instance_user}@${aws_instance.private_bastion.private_ip}:",
      "scp -q -o StrictHostKeyChecking=no -i ~/${var.prefix}.pem ~/terraform-enterprise.tar ${var.instance_user}@${aws_instance.private_bastion.private_ip}:",
      "scp -q -o StrictHostKeyChecking=no -i ~/${var.prefix}.pem ~/tfc-agent.tar ${var.instance_user}@${aws_instance.private_bastion.private_ip}:",
      "scp -q -o StrictHostKeyChecking=no -i ~/${var.prefix}.pem ~/nginx-bundle.tar ${var.instance_user}@${aws_instance.private_bastion.private_ip}:",
      "scp -q -o StrictHostKeyChecking=no -i ~/${var.prefix}.pem ~/linux-amd64/helm ${var.instance_user}@${aws_instance.private_bastion.private_ip}:",
      "scp -q -o StrictHostKeyChecking=no -i ~/${var.prefix}.pem ~/aws-load-balancer-controller-*.tgz ${var.instance_user}@${aws_instance.private_bastion.private_ip}:",
      "scp -q -o StrictHostKeyChecking=no -i ~/${var.prefix}.pem ~/terraform-enterprise-*.tgz ${var.instance_user}@${aws_instance.private_bastion.private_ip}:",

      "scp -q -o StrictHostKeyChecking=no -i ~/${var.prefix}.pem -r ~/gitlab-installer ${var.instance_user}@${aws_instance.gitlab.private_ip}:"
    ]
  }
}

resource "terraform_data" "private_bastion" {
  depends_on = [
    terraform_data.public_bastion
  ]

  connection {
    bastion_host        = aws_instance.public_bastion.public_ip
    bastion_user        = var.instance_user
    bastion_private_key = tls_private_key.main.private_key_pem

    host        = aws_instance.private_bastion.private_ip
    user        = var.instance_user
    private_key = tls_private_key.main.private_key_pem

    timeout = "2m"
  }

  provisioner "file" {
    source      = "./cert"
    destination = "/home/${var.instance_user}"
  }

  provisioner "file" {
    content     = var.tfe_license
    destination = "/home/${var.instance_user}/terraform.hclic"
  }

  provisioner "file" {
    content     = yamlencode(local.aws_load_balancer_controller_yaml)
    destination = "/home/${var.instance_user}/aws-load-balancer-controller.yaml"
  }

  provisioner "file" {
    content     = yamlencode(local.tfe_yaml)
    destination = "/home/${var.instance_user}/terraform.yaml"
  }

  provisioner "file" {
    content     = yamlencode(local.tfe_agent_service_account_yaml)
    destination = "/home/${var.instance_user}/terraform-agent-sa.yaml"
  }

  provisioner "file" {
    content     = local.bundle_yaml
    destination = "/home/${var.instance_user}/bundle.yaml"
  }

  provisioner "remote-exec" {
    script = "./scripts/private.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.main.repository_url}",

      #################### Image ####################
      # AWS Load Balancer Controller
      "docker load -q -i ~/aws-load-balancer-controller.tar",
      "docker tag $(docker images public.ecr.aws/eks/aws-load-balancer-controller --format \"{{.Repository}}:{{.Tag}}\") ${aws_ecr_repository.main.repository_url}:aws-load-balancer-controller",
      "docker push ${aws_ecr_repository.main.repository_url}:aws-load-balancer-controller",
      "rm -rf ~/aws-load-balancer-controller.tar",

      # Terraform Enterprise
      "docker load -q -i ~/terraform-enterprise.tar",
      "docker tag $(docker images images.releases.hashicorp.com/hashicorp/terraform-enterprise --format \"{{.Repository}}:{{.Tag}}\") ${aws_ecr_repository.main.repository_url}:terraform-enterprise",
      "docker push ${aws_ecr_repository.main.repository_url}:terraform-enterprise",
      "rm -rf ~/terraform-enterprise.tar",

      # TFE Agent
      "docker load -q -i ~/tfc-agent.tar",
      "mkdir -p ~/tfc-agent",
      "cp ~/cert/ca.crt ~/tfc-agent",
      "cat > ~/tfc-agent/Dockerfile << 'EOF'",
      "FROM hashicorp/tfc-agent:v1",
      "USER root",
      "ADD ca.crt /usr/local/share/ca-certificates",
      "RUN update-ca-certificates",
      "USER tfc-agent",
      "EOF",
      "docker build --no-cache -t hashicorp/tfc-agent:latest ~/tfc-agent",
      "docker tag hashicorp/tfc-agent:latest ${aws_ecr_repository.main.repository_url}:tfc-agent",
      "docker push ${aws_ecr_repository.main.repository_url}:tfc-agent",
      "rm -rf ~/tfc-agent.tar",

      # Bundle
      "docker load -q -i ~/nginx-bundle.tar",
      "docker tag nginx:bundle ${aws_ecr_repository.main.repository_url}:bundle",
      "docker push ${aws_ecr_repository.main.repository_url}:bundle",
      "rm -rf ~/nginx-bundle.tar",


      #################### Helm Chart ####################
      "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.main.name}",

      # AWS Load Balancer Controller
      "helm install aws-load-balancer-controller ~/aws-load-balancer-controller-*.tgz --namespace ${var.tfe_lb_controller_kube_namespace} --values ~/aws-load-balancer-controller.yaml",
      "kubectl wait --for=condition=available deployment/aws-load-balancer-controller -n ${var.tfe_lb_controller_kube_namespace} --timeout=300s",
      "sleep 30s",

      # Terraform Enterprise
      ## Create TFE Namespace.
      "kubectl create namespace ${var.tfe_kube_namespace}",

      ## Secrets
      "kubectl create secret docker-registry terraform-enterprise --namespace ${var.tfe_kube_namespace} --docker-server=${split("/", aws_ecr_repository.main.repository_url)[0]} --docker-username=AWS --docker-password=$(aws ecr get-login-password --region ${var.region})",
      "kubectl create secret generic tfe-secrets --namespace=${var.tfe_kube_namespace} --from-file=TFE_LICENSE=/home/${var.instance_user}/terraform.hclic --from-literal=TFE_ENCRYPTION_PASSWORD=hashicorp --from-literal=TFE_DATABASE_PASSWORD=${var.db_password}",
      "kubectl create secret tls tfe-certs --namespace=${var.tfe_kube_namespace} --cert=/home/${var.instance_user}/cert/cert.pem --key=/home/${var.instance_user}/cert/key.pem",

      "helm install terraform-enterprise terraform-enterprise-*.tgz --namespace ${var.tfe_kube_namespace} --values ~/terraform.yaml",
      "sleep 60s",

      # TFE Agent
      "kubectl create --namespace ${var.tfe_kube_namespace}-agents -f ~/terraform-agent-sa.yaml",

      # Bundle
      "kubectl apply -f ~/bundle.yaml"
    ]
  }
}

data "template_file" "gitlab" {
  template = file("${path.module}/config/gitlab.rb.tpl")

  vars = {
    gitlab_domain = var.gitlab_domain
    cert_path     = "/home/${var.instance_user}/cert/service.crt"
    key_path      = "/home/${var.instance_user}/cert/service.key"
    temp_password = "temp_password"
  }
}

resource "terraform_data" "gitlab" {
  depends_on = [
    terraform_data.public_bastion
  ]

  connection {
    bastion_host        = aws_instance.public_bastion.public_ip
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
      "sudo dnf install --skip-broken --disablerepo=\"*\" --nogpgcheck -qq -y ~/gitlab-installer/*.rpm",
      "sudo mv ~/gitlab.rb /etc/gitlab/gitlab.rb",
      "sudo mkdir /etc/gitlab/trusted-certs",
      "sudo cp ~/cert/ca.crt /etc/gitlab/trusted-certs",
      "sudo gitlab-ctl reconfigure"
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
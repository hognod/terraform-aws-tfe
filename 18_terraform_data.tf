locals {
  values_yaml = {
    replicaCount = 2

    tls = {
      certificateSecret = "tfe-certs"
      caCertData        = base64encode(file("./cert/bundle.pem"))
    }

    image = {
      repository = "images.releases.hashicorp.com"
      name       = "hashicorp/terraform-enterprise"
      tag        = "v202507-1"
    }

    serviceAccount = {
      enabled = true
      name    = var.tfe_kube_svc_account
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.irsa.arn
      }
    }

    tfe = {
      privateHttpPort  = 8080
      privateHttpsPort = 8443
      metrics = {
        enable    = false
        httpPort  = 9090
        httpsPort = 9091
      }
    }

    service = {
      annotations = {
        "service.beta.kubernetes.io/aws-load-balancer-type"             = "nlb"
        "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "tcp"
        "service.beta.kubernetes.io/aws-load-balancer-scheme"           = "internal"
        "service.beta.kubernetes.io/aws-load-balancer-subnets"          = "${aws_subnet.private-a.id},${aws_subnet.private-b.id}"
        "service.beta.kubernetes.io/aws-load-balancer-security-groups"  = ""
      }
      type = "LoadBalancer"
      port = 443
    }

    env = {
      secretRefs = [
        {
          name = "tfe-secrets"
        }
      ]

      variables = {
        # TFE configuration settings
        TFE_HOSTNAME = var.tfe_hostname

        # Database settings
        TFE_DATABASE_HOST       = aws_db_instance.main.endpoint
        TFE_DATABASE_NAME       = var.db_name
        TFE_DATABASE_USER       = var.db_username
        TFE_DATABASE_PARAMETERS = "sslmode=require"

        # Object storage settings
        TFE_OBJECT_STORAGE_TYPE                                 = "s3"
        TFE_OBJECT_STORAGE_S3_BUCKET                            = aws_s3_bucket.main.id
        TFE_OBJECT_STORAGE_S3_REGION                            = var.region
        TFE_OBJECT_STORAGE_S3_USE_INSTANCE_PROFILE              = "true"
        TFE_OBJECT_STORAGE_S3_SERVER_SIDE_ENCRYPTION            = "AES256"
        TFE_OBJECT_STORAGE_S3_SERVER_SIDE_ENCRYPTION_KMS_KEY_ID = ""

        # Redis settings
        TFE_REDIS_HOST     = "${aws_elasticache_cluster.main.cache_nodes[0].address}:${aws_elasticache_cluster.main.cache_nodes[0].port}"
        TFE_REDIS_USE_AUTH = "false"
        TFE_REDIS_USE_TLS  = "false"
      }
    }

    resources = {
      requests = {
        memory = "8192Mi"
        cpu    = "2000m"
      }
    }

    agentWorkerPodTemplate = {
      spec = {
        containers = [
          {
            name = "terraform-enterprise-agent"
            resources = {
              requests = {
                cpu    = "2000m"
                memory = "4Gi"
              }
            }
          }
        ]
      }
    }
  }
}

resource "terraform_data" "public" {
  depends_on = [
    aws_eks_node_group.main
  ]

  connection {
    host        = aws_instance.public.public_ip
    user        = var.instance_user
    private_key = tls_private_key.main.private_key_pem

    timeout = "2m"
  }

  input = {
      tfe_kube_namespace = var.tfe_kube_namespace
    }

  provisioner "file" {
    source      = "./cert"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    on_failure = continue

    inline = [
      "cp -r /tmp/cert ~/cert",

      "echo \"${yamlencode(local.values_yaml)}\" > test.yaml",
      "echo ${var.tfe_license} > terraform.hclic",
      # aws cli install
      "curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o \"awscliv2.zip\"",
      "sudo apt install -y unzip",
      "unzip awscliv2.zip",
      "sudo ./aws/install",
      "aws configure set aws_access_key_id ${var.access_key}",
      "aws configure set aws_secret_access_key ${var.secret_key}",
      "aws configure set region ${var.region}",

      "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.main.name}",
      # kubectl install
      "curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\"",
      "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
      # helm install
      "curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4",
      "chmod 700 get_helm.sh",
      "./get_helm.sh",

      "echo 'alias k=\"kubectl\"' >> ~/.bashrc",

      # tfe install
      ## aws load balancer controller install
      "helm repo add eks https://aws.github.io/eks-charts",
      "helm repo update eks",
      "helm install aws-load-balancer-controller eks/aws-load-balancer-controller --namespace ${var.tfe_lb_controller_kube_namespace} --set clusterName=${aws_eks_cluster.main.name} --set serviceAccount.create=true --set serviceAccount.name=${var.tfe_lb_controller_kube_svc_account} --set serviceAccount.annotations.\"eks\\.amazonaws\\.com/role-arn\"=${aws_iam_role.lb_controller_irsa.arn} --set region=${var.region} --set vpcId=${aws_vpc.main.id}",

      "kubectl create namespace ${var.tfe_kube_namespace}",

      ## Secrets
      "kubectl create secret docker-registry terraform-enterprise --namespace ${var.tfe_kube_namespace} --docker-server=images.releases.hashicorp.com --docker-username=terraform --docker-password=${var.tfe_license}",
      "kubectl create secret generic tfe-secrets --namespace=${var.tfe_kube_namespace} --from-file=TFE_LICENSE=$(pwd)/terraform.hclic --from-literal=TFE_ENCRYPTION_PASSWORD=hashicorp --from-literal=TFE_DATABASE_PASSWORD=${var.db_password}",
      "kubectl create secret tls tfe-certs --namespace=${var.tfe_kube_namespace} --cert=$(pwd)/cert/cert.pem --key=$(pwd)/cert/key.pem",

      "helm repo add hashicorp https://helm.releases.hashicorp.com",
      "helm install terraform-enterprise hashicorp/terraform-enterprise --namespace ${var.tfe_kube_namespace} --values test.yaml"
    ]
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "helm delete terraform-enterprise --namespace ${self.output.tfe_kube_namespace}"
    ]
  }
}
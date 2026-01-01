locals {
  tfe_yaml = {
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

    # TFE가 S3 사용하는 용도 Agent용은 별도로 생성 필요
    serviceAccount = {
      enabled = true
      name    = var.tfe_kube_svc_account
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.s3_irsa_role.arn
      }
    }

    agentWorkerPodTemplate = {
      spec = {
        serviceAccountName = var.tfe_agent_kube_svc_account
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
        "service.beta.kubernetes.io/aws-load-balancer-name"             = var.tfe_lb_name
        "service.beta.kubernetes.io/aws-load-balancer-type"             = "nlb-ip"
        "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "tcp"
        "service.beta.kubernetes.io/aws-load-balancer-internal"         = "\"true\""
        "service.beta.kubernetes.io/aws-load-balancer-subnets"          = "${aws_subnet.private-a.id},${aws_subnet.private-c.id}"
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
        TFE_HOSTNAME = var.tfe_domain

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
  }

  tfe_agent_service_account_yaml = {
    apiVersion = "v1"
    kind       = "ServiceAccount"
    metadata = {
      name      = var.tfe_agent_kube_svc_account
      namespace = "${var.tfe_kube_namespace}-agents"
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.agent_irsa_role.arn
      }
    }
  }
}
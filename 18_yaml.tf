locals {
  aws_load_balancer_controller_yaml = {
    clusterName = aws_eks_cluster.main.name

    image = {
      repository = aws_ecr_repository.main.repository_url
      tag        = "aws-load-balancer-controller"
    }

    serviceAccount = {
      create = true
      name   = var.tfe_lb_controller_kube_svc_account
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.lb_controller_irsa_role.arn
      }

      region = var.region
      vpcId  = aws_vpc.main.id
    }
  }

  tfe_yaml = {
    replicaCount = 1

    tls = {
      certificateSecret = "tfe-certs"
      caCertData        = base64encode(file("./cert/bundle.pem"))
    }

    image = {
      repository = split("/", aws_ecr_repository.main.repository_url)[0]
      name       = split("/", aws_ecr_repository.main.repository_url)[1]
      tag        = "terraform-enterprise"
    }

    tfe = {
      metrics = {
        enable    = false
        httpPort  = 9090
        httpsPort = 9091
      }
      privateHttpPort  = 8080
      privateHttpsPort = 8443
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

    service = {
      annotations = {
        "service.beta.kubernetes.io/aws-load-balancer-name"             = var.tfe_lb_name
        "service.beta.kubernetes.io/aws-load-balancer-type"             = "nlb-ip"
        "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "tcp"
        "service.beta.kubernetes.io/aws-load-balancer-internal"         = "true"
        "service.beta.kubernetes.io/aws-load-balancer-subnets"          = "${aws_subnet.private-a.id},${aws_subnet.private-c.id}"
        "service.beta.kubernetes.io/aws-load-balancer-security-groups"  = "${aws_security_group.lb.id}"
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
        TFE_HOSTNAME           = var.tfe_domain
        TFE_RUN_PIPELINE_IMAGE = "${aws_ecr_repository.main.repository_url}:tfc-agent"

        # Database settings
        TFE_DATABASE_HOST       = aws_db_instance.main.endpoint
        TFE_DATABASE_NAME       = var.db_name
        TFE_DATABASE_USER       = var.db_username
        TFE_DATABASE_PARAMETERS = "sslmode=require"

        # Object storage settings
        TFE_OBJECT_STORAGE_TYPE                      = "s3"
        TFE_OBJECT_STORAGE_S3_BUCKET                 = aws_s3_bucket.main.id
        TFE_OBJECT_STORAGE_S3_REGION                 = var.region
        TFE_OBJECT_STORAGE_S3_USE_INSTANCE_PROFILE   = "true"
        TFE_OBJECT_STORAGE_S3_SERVER_SIDE_ENCRYPTION = "AES256"
        TFE_OBJECT_STORAGE_S3_USE_INSTANCE_PROFILE   = true

        # Redis settings
        TFE_REDIS_HOST     = "${aws_elasticache_cluster.main.cache_nodes[0].address}:${aws_elasticache_cluster.main.cache_nodes[0].port}"
        TFE_REDIS_USE_AUTH = "false"
        TFE_REDIS_USE_TLS  = "false"
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

  _bundle_yaml_list = [
    {
      apiVersion = "apps/v1"
      kind       = "Deployment"
      metadata = {
        name      = "bundle"
        namespace = var.tfe_kube_namespace
        labels = {
          app = "terraform-providers"
        }
      }
      spec = {
        replicas = 1
        selector = {
          matchLabels = {
            app = "terraform-providers"
          }
        }
        template = {
          metadata = {
            labels = {
              app = "terraform-providers"
            }
          }
          spec = {
            containers = [
              {
                name  = "bundle"
                image = "${aws_ecr_repository.main.repository_url}:bundle"
                ports = [
                  {
                    containerPort = 8080
                    name          = "http"
                    protocol      = "TCP"
                  }
                ]
                livenessProbe = {
                  httpGet = {
                    path = "/health"
                    port = 8080
                  }
                  initialDelaySeconds = 10
                  periodSeconds       = 10
                }
                readinessProbe = {
                  httpGet = {
                    path = "/health"
                    port = 8080
                  }
                  initialDelaySeconds = 5
                  periodSeconds       = 5
                }
              }
            ]
          }
        }
      }
    },
    {
      apiVersion = "v1"
      kind       = "Service"
      metadata = {
        name      = "bundle"
        namespace = var.tfe_kube_namespace
        labels = {
          app = "terraform-providers"
        }
      }
      spec = {
        type = "ClusterIP"
        selector = {
          app = "terraform-providers"
        }
        ports = [
          {
            port       = 8080
            targetPort = 8080
            protocol   = "TCP"
            name       = "http"
          }
        ]
        sessionAffinity = "None"
      }
    }
  ]

  bundle_yaml = join("\n---\n", [for item in local._bundle_yaml_list : yamlencode(item)])
}
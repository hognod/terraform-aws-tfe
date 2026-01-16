resource "aws_eks_cluster" "main" {
  depends_on = [
    aws_vpc_endpoint.eks,
    aws_vpc_endpoint.ec2,
    aws_vpc_endpoint.ecr_api,
    aws_vpc_endpoint.ecr_dkr,
    aws_vpc_endpoint.elb,
    aws_vpc_endpoint.sts,
    aws_vpc_endpoint.s3
  ]

  name     = "${var.prefix}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  # Kube-porxy, AWS-CNI, CoreDNS 리소스 Add-On 사용
  # true 지정 시 Terraform 자체적으로 Kube-porxy, AWS-CNI, CoreDNS 프로비저닝
  bootstrap_self_managed_addons = false

  access_config {
    authentication_mode = "API" # API_AND_CONFIG_MAP / CONFIG_MAP / API
  }

  vpc_config {
    subnet_ids = [
      aws_subnet.private-a.id,
      aws_subnet.private-c.id
    ]
    security_group_ids = [
      aws_security_group.eks-cluster.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = false
    public_access_cidrs     = null
  }

  kubernetes_network_config {
    ip_family = "ipv4"

    # It must not overlap with the VPC's CIDR.
    service_ipv4_cidr = "10.100.0.0/24"
  }

  upgrade_policy {
    support_type = "STANDARD" # STANDARD / EXTENDED
  }

  tags = {
    Name = "${var.prefix}-eks-cluster"
  }
}

resource "aws_eks_access_entry" "main" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = data.aws_iam_session_context.current.issuer_arn

  tags = {
    Name = "${var.prefix}-eks-access-entry"
  }
}

resource "aws_eks_access_policy_association" "main" {
  cluster_name = aws_eks_cluster.main.name

  access_scope {
    type       = "cluster" # cluster / namespace
    namespaces = []
  }

  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = data.aws_iam_session_context.current.issuer_arn
}

############### Bastion EC2 -> EKS Cluster Access 권한(AWS Credential 입력없이 ~/.kube/config 작성) ###############
resource "aws_eks_access_entry" "bastion" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.private_bastion_role.arn

  tags = {
    Name = "${var.prefix}-bastion-eks-access-entry"
  }
}

resource "aws_eks_access_policy_association" "bastion" {
  cluster_name = aws_eks_cluster.main.name

  access_scope {
    type       = "cluster"
    namespaces = []
  }

  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.private_bastion_role.arn
}

############### Add-on ###############
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "core_dns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"
}
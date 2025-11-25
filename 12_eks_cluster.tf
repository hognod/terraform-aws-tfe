resource "aws_eks_cluster" "main" {
  name     = "hognod-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  access_config {
    authentication_mode = "API" # API_AND_CONFIG_MAP / CONFIG_MAP / API
  }

  vpc_config {
    subnet_ids = [
      aws_subnet.private-a.id,
      aws_subnet.private-b.id
    ]
    security_group_ids = [
      aws_security_group.eks-cluster.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = false
    public_access_cidrs     = null
  }

  kubernetes_network_config {
    ip_family         = "ipv4"
    
    # It must not overlap with the VPC's CIDR.
    service_ipv4_cidr = "10.100.0.0/24"
  }

  tags = {
    Name = "hognod-eks-cluster"
  }
}

resource "aws_eks_access_entry" "main" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = data.aws_iam_session_context.current.issuer_arn

  tags = {
    Name = "hognod-eks-access-entry"
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
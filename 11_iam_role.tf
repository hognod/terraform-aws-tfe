# EKS Cluster
data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster" {
  name = "hognod-eks-cluster-role"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json

  tags = {
    Name = "hognod-eks-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

# EKS Node group
data "aws_iam_policy_document" "eks_node_group_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_node_group" {
  name = "hognod-eks-node-group-role"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.eks_node_group_assume_role.json

  tags = {
    Name = "hognod-eks-node-group-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_node_group_worker_node_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_cni_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_container_registry_readonly" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group.name
}

# IRSA
data "aws_iam_policy_document" "irsa_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.main.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace("${aws_iam_openid_connect_provider.main.arn}", "/^(.*provider/)/", "")}:sub"
      values   = ["system:serviceaccount:${var.tfe_kube_namespace}:${var.tfe_kube_svc_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace("${aws_iam_openid_connect_provider.main.arn}", "/^(.*provider/)/", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "irsa" {
  name = "hognod-irsa-role"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.irsa_assume_role.json

  tags = {
    Name = "hognod-irsa-role"
  }
}

//////////
data "aws_iam_policy_document" "workload_identity_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:GetBucketLocation"
    ]
    resources = [
      "${aws_s3_bucket.main.arn}",
      "${aws_s3_bucket.main.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "workload_identity_combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.workload_identity_s3.json
  ]
}

resource "aws_iam_policy" "workload_identity" {
  name        = "hognod-irsa-workload-policy"
  policy      = data.aws_iam_policy_document.workload_identity_combined.json
}

resource "aws_iam_role_policy_attachment" "irsa_role_policy_attachment" {
  role       = aws_iam_role.irsa.name
  policy_arn = aws_iam_policy.workload_identity.arn
}


# IRSA for aws_lb_controller
data "aws_iam_policy_document" "lb_controller_irsa_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.main.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace("${aws_iam_openid_connect_provider.main.arn}", "/^(.*provider/)/", "")}:sub"
      values   = ["system:serviceaccount:${var.tfe_lb_controller_kube_namespace}:${var.tfe_lb_controller_kube_svc_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace("${aws_iam_openid_connect_provider.main.arn}", "/^(.*provider/)/", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lb_controller_irsa" {
  name = "hognod-lb-controller-irsa-role"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.lb_controller_irsa_assume_role.json

  tags = {
    Name = "hognod-lb-controller-irsa-role"
  }
}

//////////
data "aws_iam_policy_document" "lb_controller_irsa_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["elasticloadbalancing.amazonaws.com"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeTags"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lb_controller_irsa_policy" {
  name        = "hognod-lb-controller-irsa-policy"
  policy      = data.aws_iam_policy_document.lb_controller_irsa_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "lb_controller_irsa_role_policy_attachment" {
  role       = aws_iam_role.lb_controller_irsa.name
  policy_arn = aws_iam_policy.lb_controller_irsa_policy.arn
}
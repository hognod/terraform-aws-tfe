############### EKS Cluster ###############
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

############### EKS Node group ###############
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

############### S3 IRSA Role ###############
data "aws_iam_policy_document" "s3_irsa_trust_relationship" {
  statement {
    effect  = "Allow"
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

resource "aws_iam_role" "s3_irsa_role" {
  name = "${var.prefix}-s3-irsa-role"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.s3_irsa_trust_relationship.json

  tags = {
    Name = "${var.prefix}-s3-irsa-role"
  }
}

data "aws_iam_policy_document" "s3_irsa_policy" {
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

resource "aws_iam_policy" "s3_irsa_policy" {
  name   = "${var.prefix}-s3-irsa-policy"
  policy = data.aws_iam_policy_document.s3_irsa_policy.json
}

resource "aws_iam_role_policy_attachment" "s3_irsa_role_policy_attachment" {
  role       = aws_iam_role.s3_irsa_role.name
  policy_arn = aws_iam_policy.s3_irsa_policy.arn
}


############### AWS LB Controller IRSA Role ###############
data "aws_iam_policy_document" "lb_controller_irsa_trust_relationship" {
  statement {
    effect  = "Allow"
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
      values   = ["system:serviceaccount:${var.tfe_lb_controller_kube_namespace}:${var.tfe_lb_controller_kube_svc_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace("${aws_iam_openid_connect_provider.main.arn}", "/^(.*provider/)/", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lb_controller_irsa_role" {
  name = "${var.prefix}-lb-controller-irsa-role"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.lb_controller_irsa_trust_relationship.json

  tags = {
    Name = "${var.prefix}-lb-controller-irsa-role"
  }
}

data "aws_iam_policy_document" "lb_controller_irsa_policy" {
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
      "ec2:DescribeTags",
      "ec2:GetCoipPoolUsage",
      "ec2:DescribeCoipPools",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTrustStores",
      "elasticloadbalancing:DescribeListenerAttributes"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "cognito-idp:DescribeUserPoolClient",
      "acm:ListCertificates",
      "acm:DescribeCertificate",
      "iam:ListServerCertificates",
      "iam:GetServerCertificate",
      "waf-regional:GetWebACL",
      "waf-regional:GetWebACLForResource",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
      "shield:GetSubscriptionState",
      "shield:DescribeProtection",
      "shield:CreateProtection",
      "shield:DeleteProtection"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateSecurityGroup"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateTags"
    ]
    resources = ["arn:aws:ec2:*:*:security-group/*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["CreateSecurityGroup"]
    }
    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]
    resources = ["arn:aws:ec2:*:*:security-group/*"]
    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["true"]
    }
    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DeleteSecurityGroup"
    ]
    resources = ["*"]
    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup"
    ]
    resources = ["*"]
    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:DeleteRule"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags"
    ]
    resources = [
      "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
    ]
    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["true"]
    }
    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags"
    ]
    resources = [
      "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:ModifyListenerAttributes"
    ]
    resources = ["*"]
    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:AddTags"
    ]
    resources = [
      "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "elasticloadbalancing:CreateAction"
      values   = ["CreateTargetGroup", "CreateLoadBalancer"]
    }
    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets"
    ]
    resources = ["arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:SetWebAcl",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:ModifyRule"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lb_controller_irsa_policy" {
  name   = "${var.prefix}-lb-controller-irsa-policy"
  policy = data.aws_iam_policy_document.lb_controller_irsa_policy.json
}

resource "aws_iam_role_policy_attachment" "lb_controller_irsa_role_policy_attachment" {
  role       = aws_iam_role.lb_controller_irsa_role.name
  policy_arn = aws_iam_policy.lb_controller_irsa_policy.arn
}

############### TFE Agent IRSA Role ###############
data "aws_iam_policy_document" "agent_irsa_trust_relationship" {
  statement {
    effect  = "Allow"
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
      values   = ["system:serviceaccount:${var.tfe_kube_namespace}-agents:${var.tfe_agent_kube_svc_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace("${aws_iam_openid_connect_provider.main.arn}", "/^(.*provider/)/", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "agent_irsa_role" {
  name = "${var.prefix}-agent-irsa-role"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.agent_irsa_trust_relationship.json

  tags = {
    Name = "${var.prefix}-agent-irsa-role"
  }
}

data "aws_iam_policy_document" "agent_irsa_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      aws_iam_role.assume_role.arn
    ]
  }
}

resource "aws_iam_policy" "agent_irsa_policy" {
  name = "${var.prefix}-agent-irsa-policy"
  policy = data.aws_iam_policy_document.agent_irsa_policy.json
}

resource "aws_iam_role_policy_attachment" "agent_irsa_policy_attachment" {
  role = aws_iam_role.agent_irsa_role.name
  policy_arn = aws_iam_policy.agent_irsa_policy.arn
}

############### Assume Role ###############
data "aws_iam_policy_document" "assume_role_trust_relationship" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.agent_irsa_role.arn
      ]
    }
  }
}

resource "aws_iam_role" "assume_role" {
  name = "${var.prefix}-assume-role"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.agent_irsa_trust_relationship.json
}

# AdministratorAccess
resource "aws_iam_role_policy_attachment" "assume_role_policy_attachment" {
  role = aws_iam_role.assume_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
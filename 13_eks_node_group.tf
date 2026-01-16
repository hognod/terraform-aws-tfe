resource "aws_eks_node_group" "main" {
  depends_on = [
    aws_eks_addon.kube_proxy,
    aws_eks_addon.core_dns,
    aws_eks_addon.vpc_cni
  ]

  cluster_name = aws_eks_cluster.main.name

  node_group_name = "${var.prefix}-eks-node-group"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids = [
    aws_subnet.private-a.id,
    aws_subnet.private-c.id
  ]
  capacity_type = "ON_DEMAND" # ON_DEMAND / SPOT
  instance_types = [
    var.node_group_instance_type
  ]
  ami_type = var.node_group_ami_type

  launch_template {
    id      = aws_launch_template.main.id
    version = aws_launch_template.main.latest_version
  }

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Name = "${var.prefix}-eks-node-group"
  }
}


// Launch Template
locals {
  eks_default_ami_map = {
    // https://github.com/awslabs/amazon-eks-ami/releases
    AL2023_ARM_64_STANDARD     = "al2023-ami-minimal-2023.*-arm64"
    AL2023_x86_64_STANDARD     = "al2023-ami-minimal-2023.*-x86_64"
    AL2_ARM_64                 = "amzn2-ami-minimal-hvm-2.0.*-arm64-ebs"
    AL2_x86_64                 = "amzn2-ami-minimal-hvm-2.0.*-x86_64-ebs"
    AL2_x86_64_GPU             = "amzn2-ami-minimal-hvm-2.0.*-x86_64-ebs"
    BOTTLEROCKET_ARM_64        = "bottlerocket-aws-k8s-*-aarch64-*"
    BOTTLEROCKET_x86_64        = "bottlerocket-aws-k8s-*-x86_64-*"
    BOTTLEROCKET_ARM_64_NVIDIA = "bottlerocket-aws-k8s-*-nvidia-aarch64-*"
    BOTTLEROCKET_x86_64_NVIDIA = "bottlerocket-aws-k8s-*-nvidia-x86_64-*"
  }
}

data "aws_ami" "main" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"
    values = [
      lookup(local.eks_default_ami_map, var.node_group_ami_type)
    ]
  }
}

resource "aws_launch_template" "main" {
  name = "${var.prefix}-launch-template"

  network_interfaces {
    associate_public_ip_address = false
    security_groups = [
      aws_security_group.node_group.id
    ]
  }

  block_device_mappings {
    device_name = data.aws_ami.main.root_device_name

    ebs {
      volume_size           = var.node_group_disk_size
      delete_on_termination = true
      encrypted             = false
    }
  }

  ebs_optimized = true

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.prefix}-node"
    }
  }

  tags = {
    Name = "${var.prefix}-node-group"
  }
}
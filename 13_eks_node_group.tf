resource "aws_eks_node_group" "main" {
  cluster_name = aws_eks_cluster.main.name

  node_group_name = "hognod-eks-node-group"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids = [
    aws_subnet.private-a.id,
    aws_subnet.private-b.id
  ]
  capacity_type = "ON_DEMAND" # ON_DEMAND / SPOT
  instance_types = [
    var.node_group_instance_type
  ]
  ami_type  = var.node_group_ami_type
  disk_size = var.node_group_disk_size

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
    Name = "hognod-eks-node-group"
  }
}

resource "aws_launch_template" "main" {
  name = "hognod-launch-template"

  network_interfaces {
    associate_public_ip_address = false
    security_groups = [
      aws_security_group.node_group.id
    ]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "hognod-node"
    }
  }

  tags = {
    Name = "hognod-node-group"
  }
}
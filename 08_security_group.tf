# Instance
resource "aws_security_group" "public" {
  name   = "hognod-public"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "TCP"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 80
    to_port   = 80
    protocol  = "TCP"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 443
    to_port   = 443
    protocol  = "TCP"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 22
    to_port   = 22
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-b.cidr_block
    ]
  }

  tags = {
    Name = "hognod-public"
  }
}

# EKS
resource "aws_security_group" "eks-cluster" {
  name   = "hognod-eks-cluster"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-b.cidr_block
    ]
    description = "Allow TCP/443 (HTTPS) inbound to EKS cluster from node group."
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    description = "Allow all outbound traffic from EKS cluster."
  }

  tags = {
    Name = "hognod-eks-cluster"
  }
}

# Node Group
resource "aws_security_group" "node_group" {
  name   = "hognod-node-group"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-b.cidr_block
    ]
    description = "Allow TCP/443 (HTTPS) inbound to node group from TFE load balancer."
  }

  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-b.cidr_block
    ]
    description = "Allow TCP/8080 or specified port (TFE HTTP) inbound to node group from TFE load balancer."
  }

  ingress {
    from_port = 8443
    to_port   = 8443
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-b.cidr_block
    ]
    description = "Allow TCP/8443 or specified port (TFE HTTPS) inbound to node group from TFE load balancer."
  }

  ingress {
    from_port = 10250
    to_port   = 10250
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-b.cidr_block
    ]
    description = "Allow TCP/10250 (kubelet) inbound to node group from EKS cluster (cluster API)."
  }

  ingress {
    from_port = 4443
    to_port   = 4443
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-b.cidr_block
    ]
    description = "Allow TCP/4443 (webhooks) inbound to node group from EKS cluster (cluster API)."
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "TCP"
    self        = true
    description = "Allow TCP/53 (CoreDNS) inbound between nodes in node group."
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "UDP"
    self        = true
    description = "Allow UDP/53 (CoreDNS) inbound between nodes in node group."
  }

  ingress {
    from_port   = 1025
    to_port     = 65535
    protocol    = "TCP"
    self        = true
    description = "Allow TCP/1025-TCP/65535 (ephemeral ports) inbound between nodes in node group."
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    description = "Allow all outbound traffic from node group."
  }
}

# Elasticache
resource "aws_security_group" "ealsticache" {
  name   = "hognod-elasticache"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 6379
    to_port   = 6379
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-b.cidr_block
    ]
  }

  tags = {
    Name = "hognod-elasticache"
  }
}

#RDS
resource "aws_security_group" "rds" {
  name   = "hognod-rds"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-b.cidr_block
    ]
  }

  tags = {
    Name = "hognod-rds"
  }
}
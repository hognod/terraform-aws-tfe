## Endpoints
resource "aws_security_group" "endpoint" {
  name   = "${var.prefix}-endpoint"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "TCP"
    cidr_blocks = [
      aws_vpc.main.cidr_block
    ]
  }

  tags = {
    Name = "${var.prefix}-endpoint"
  }
}

############### Instance ###############
## Public Bastion
resource "aws_security_group" "public-bastion" {
  name   = "${var.prefix}-public-bastion"
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
      aws_subnet.private-c.cidr_block
    ]
  }

  tags = {
    Name = "${var.prefix}-public-bastion"
  }
}

## Private Bastion
resource "aws_security_group" "private-bastion" {
  name   = "${var.prefix}-private-bastion"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.public-a.cidr_block
    ]
  }

  egress {
    from_port = 80
    to_port   = 80
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-b.cidr_block
    ]
  }

  egress {
    from_port = 443
    to_port   = 443
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-b.cidr_block
    ]
  }

  tags = {
    Name = "${var.prefix}-private-bastion"
  }
}

## windows bastion
resource "aws_security_group" "windows" {
  name   = "${var.prefix}-windows-bastion"
  vpc_id = aws_vpc.main.id

  # RDP
  ingress {
    from_port = 3389
    to_port   = 3389
    protocol  = "TCP"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Name = "${var.prefix}-windows-bastion"
  }
}

## GitLab
resource "aws_security_group" "gitlab" {
  name   = "${var.prefix}-gitlab"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.public-a.cidr_block
    ]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-c.cidr_block
    ]
  }

  egress {
    from_port = 443
    to_port   = 443
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-c.cidr_block
    ]
  }

  tags = {
    Name = "${var.prefix}-gitlab"
  }
}

############### Load Balancer ###############
resource "aws_security_group" "lb" {
  name   = "hognod-lb"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.public-a.cidr_block, # windows bastion
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-b.cidr_block
    ]
  }

  ingress {
    from_port = 8446
    to_port   = 8446
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.public-a.cidr_block, # windows bastion
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-b.cidr_block
    ]
  }

  egress {
    from_port = 8443
    to_port   = 8443
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-b.cidr_block
    ]
  }

  ingress {
    from_port = 8446
    to_port   = 8446
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-b.cidr_block
    ]
  }

  tags = {
    Name = "hognod-lb"
  }
}

############### EKS ###############
resource "aws_security_group" "eks-cluster" {
  name   = "${var.prefix}-eks-cluster"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-c.cidr_block
    ]
    description = "Allow TCP/443 (HTTPS) inbound to EKS cluster from node group & private bastion."
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
    Name = "${var.prefix}-eks-cluster"
  }
}

############### Node Group ###############
resource "aws_security_group" "node_group" {
  name   = "${var.prefix}-node-group"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 8446
    to_port   = 8446
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-c.cidr_block
    ]
    description = "Allow TCP/8446 (HTTPS) inbound to node group from TFE load balancer.(AdminHttpsPort)"
  }

  ingress {
    from_port = 8443
    to_port   = 8443
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-c.cidr_block
    ]
    description = "Allow TCP/8443 or specified port (TFE HTTPS) inbound to node group from TFE load balancer."
  }

  ingress {
    from_port = 10250
    to_port   = 10250
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-c.cidr_block
    ]
    description = "Allow TCP/10250 (kubelet) inbound to node group from EKS cluster (cluster API)."
  }

  ingress {
    from_port = 4443
    to_port   = 4443
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-c.cidr_block
    ]
    description = "Allow TCP/4443 (webhooks) inbound to node group from EKS cluster (cluster API)."
  }

  ingress {
    from_port = 9443
    to_port   = 9443
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-c.cidr_block
    ]
    description = "Allow TCP/9443 (ALB controller, NGINX) inbound to node group from EKS cluster (cluster API)."
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

  tags = {
    Name = "${var.prefix}-node-group"
  }
}

############### Elasticache ###############
resource "aws_security_group" "ealsticache" {
  name   = "${var.prefix}-elasticache"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 6379
    to_port   = 6379
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-c.cidr_block
    ]
  }

  tags = {
    Name = "${var.prefix}-elasticache"
  }
}

############### RDS ###############
resource "aws_security_group" "rds" {
  name   = "${var.prefix}-rds"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "TCP"
    cidr_blocks = [
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-c.cidr_block
    ]
  }

  tags = {
    Name = "${var.prefix}-rds"
  }
}
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
      aws_subnet.public-a.cidr_block
    ]
  }

  tags = {
    Name = "hognod-eks-cluster"
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
  name = "hognod-rds"
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
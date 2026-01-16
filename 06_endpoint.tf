resource "aws_vpc_endpoint" "eks" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.eks"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private-a.id,
    aws_subnet.private-c.id
  ]

  security_group_ids = [
    aws_security_group.endpoint.id
  ]

  tags = {
    Name = "${var.prefix}-eks-endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.ec2"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private-a.id,
    aws_subnet.private-c.id
  ]

  security_group_ids = [
    aws_security_group.endpoint.id
  ]

  tags = {
    Name = "${var.prefix}-ec2-endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private-a.id,
    aws_subnet.private-c.id
  ]

  security_group_ids = [
    aws_security_group.endpoint.id
  ]

  tags = {
    Name = "${var.prefix}-ecr-api-endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private-a.id,
    aws_subnet.private-c.id
  ]

  security_group_ids = [
    aws_security_group.endpoint.id
  ]

  tags = {
    Name = "${var.prefix}-ecr-dkr-endpoint"
  }
}

resource "aws_vpc_endpoint" "elb" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.elasticloadbalancing"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private-a.id,
    aws_subnet.private-c.id
  ]

  security_group_ids = [
    aws_security_group.endpoint.id
  ]

  tags = {
    Name = "${var.prefix}-elb-endpoint"
  }
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.sts"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private-a.id,
    aws_subnet.private-c.id
  ]

  security_group_ids = [
    aws_security_group.endpoint.id
  ]

  tags = {
    Name = "${var.prefix}-sts-endpoint"
  }
}


resource "aws_vpc_endpoint" "s3" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.s3"
  vpc_endpoint_type   = "Gateway"
  private_dns_enabled = false

  route_table_ids = [
    aws_route_table.private-a.id,
    aws_route_table.private-c.id,
  ]

  tags = {
    Name = "${var.prefix}-s3-endpoint"
  }
}
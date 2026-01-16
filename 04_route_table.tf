resource "aws_route_table" "public-a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = aws_vpc.main.cidr_block
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.prefix}-public-rtb-a"
  }
}

resource "aws_route_table" "private-a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = aws_vpc.main.cidr_block
    gateway_id = "local"
  }

  tags = {
    Name = "${var.prefix}-private-rtb-a"
  }
}

resource "aws_route_table" "private-c" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = aws_vpc.main.cidr_block
    gateway_id = "local"
  }

  tags = {
    Name = "${var.prefix}-private-rtb-c"
  }
}
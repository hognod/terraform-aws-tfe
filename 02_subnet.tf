resource "aws_subnet" "public-a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 0)
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-public-subnet-a"
  }
}

resource "aws_subnet" "private-a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, 1)
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "${var.prefix}-private-subnet-a"
  }
}

resource "aws_subnet" "private-c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, 10)
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "${var.prefix}-private-subnet-c"
  }
}
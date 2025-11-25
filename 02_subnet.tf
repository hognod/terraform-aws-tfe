resource "aws_subnet" "public-a" {
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, 0)
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "hognod-public-subnet-a"
  }
}

resource "aws_subnet" "private-a" {
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, 1)
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "hognod-private-subnet-a"
  }
}

resource "aws_subnet" "private-b" {
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, 10)
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "hognod-private-subnet-b"
  }
}
# IAM은 VPC Endpoint를 지원하지 않는 글로벌 서비스
# 구성된 TFE를 통해 IAM 리소스를 생성하려면 private 서브넷에서 iam.amazonaws.com 으로의 아웃바운드 경로가 필요함.


resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.prefix}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-a.id

  tags = {
    Name = "${var.prefix}-nat-gw"
  }
}

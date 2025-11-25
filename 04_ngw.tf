resource "aws_nat_gateway" "main" {
  subnet_id = aws_subnet.public-a.id
}
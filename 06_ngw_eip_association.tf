resource "aws_nat_gateway_eip_association" "main" {
  allocation_id  = aws_eip.main.id
  nat_gateway_id = aws_nat_gateway.main.id
}
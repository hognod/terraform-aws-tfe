resource "aws_eip" "main" {
  domain = "vpc"

  tags = {
    Name = "hognod-eip"
  }
}
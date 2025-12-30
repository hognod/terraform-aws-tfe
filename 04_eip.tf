resource "aws_eip" "main" {
  domain = "vpc"

  tags = {
    Name = "${var.prefix}-eip"
  }
}
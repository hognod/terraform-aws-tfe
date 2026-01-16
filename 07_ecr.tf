resource "aws_ecr_repository" "main" {
  name = var.prefix

  tags = {
    Name = "${var.prefix}-ecr"
  }
}
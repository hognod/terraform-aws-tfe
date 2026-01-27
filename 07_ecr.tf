resource "aws_ecr_repository" "main" {
  name         = var.prefix
  force_delete = true

  tags = {
    Name = "${var.prefix}-ecr"
  }
}
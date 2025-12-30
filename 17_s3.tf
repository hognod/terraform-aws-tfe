resource "aws_s3_bucket" "main" {
  bucket = "${var.prefix}-bucket"

  force_destroy = true

  tags = {
    Name = "${var.prefix}-bucket"
  }
}
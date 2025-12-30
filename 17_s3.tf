resource "aws_s3_bucket" "main" {
  # For unique
  bucket_prefix = "${var.prefix}-bucket-"

  force_destroy = true

  tags = {
    Name = "${var.prefix}-bucket"
  }
}
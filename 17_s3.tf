resource "aws_s3_bucket" "main" {
  bucket = "hognod-bucket"

  force_destroy = true

  tags = {
    Name = "hognod-bucket"
  }
}
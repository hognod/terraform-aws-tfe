resource "aws_s3_bucket" "example" {
  bucket = "hognod-bucket"

  force_destroy = true

  tags = {
    Name = "hognod-bucket"
  }
}
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  key_name   = "hognod"
  public_key = tls_private_key.main.public_key_openssh
}

//local environment
# resource "local_file" "main" {
#   content  = tls_private_key.main.private_key_pem
#   filename = "${path.module}/hognod.pem"
#   file_permission = "0400"
# }
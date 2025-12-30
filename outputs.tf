output "public_ip" {
  value = aws_instance.bastion.public_ip
}

output "public_key_openssh" {
  value = nonsensitive(tls_private_key.main.private_key_pem)
}
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "gitlab_private_ip" {
  value = aws_instance.gitlab.private_ip
}

output "public_key_openssh" {
  value = nonsensitive(tls_private_key.main.private_key_pem)
}
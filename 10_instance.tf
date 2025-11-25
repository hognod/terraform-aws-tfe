resource "aws_instance" "public" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.main.key_name

  root_block_device {
    volume_size = var.volume_size
  }

  subnet_id              = aws_subnet.public-a.id
  vpc_security_group_ids = [aws_security_group.public.id]
  private_ip             = cidrhost(aws_subnet.public-a.cidr_block, 101)

  tags = {
    Name = "hognod-public"
  }
}
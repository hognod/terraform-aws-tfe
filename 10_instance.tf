resource "aws_instance" "bastion" {
  depends_on = [
    aws_internet_gateway.igw
  ]

  ami           = var.instance_ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.main.key_name

  root_block_device {
    volume_size = var.instance_volume_size
  }

  subnet_id              = aws_subnet.public-a.id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  private_ip             = cidrhost(aws_subnet.public-a.cidr_block, 101)

  tags = {
    Name = "${var.prefix}-bastion"
  }
}

resource "aws_instance" "windows-bastion" {
  depends_on = [
    aws_internet_gateway.igw
  ]

  ami = var.windows_instance_ami_id
  instance_type = var.windows_instance_type
  key_name = aws_key_pair.main.key_name

  root_block_device {
    volume_size = var.windows_instance_volume_size
  }

  subnet_id = aws_subnet.public-a.id
  vpc_security_group_ids = [aws_security_group.windows.id]
  private_ip = cidrhost(aws_subnet.public-a.cidr_block, 102)

  tags = {
    Name = "${var.prefix}-windows-bastion"
  }
}

resource "aws_instance" "gitlab" {
  ami           = var.instance_ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.main.key_name

  root_block_device {
    volume_size = var.instance_volume_size
  }

  subnet_id              = aws_subnet.private-a.id
  vpc_security_group_ids = [aws_security_group.gitlab.id]
  private_ip             = cidrhost(aws_subnet.private-a.cidr_block, 101)

  tags = {
    Name = "${var.prefix}-gitlab"
  }
}
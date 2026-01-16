resource "aws_instance" "public_bastion" {
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
  vpc_security_group_ids = [aws_security_group.public-bastion.id]
  private_ip             = cidrhost(aws_subnet.public-a.cidr_block, 101)

  tags = {
    Name = "${var.prefix}-public-bastion"
  }
}

############### Bastion EC2 -> EKS Cluster Access 권한(AWS Credential 입력없이 ~/.kube/config 작성) ###############
resource "aws_iam_instance_profile" "private_bastion_profile" {
  name = "${var.prefix}-private-bastion-profile"
  role = aws_iam_role.private_bastion_role.name
}

resource "aws_instance" "private_bastion" {
  ami                  = var.instance_ami_id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.private_bastion_profile.name
  key_name             = aws_key_pair.main.key_name

  root_block_device {
    volume_size = var.instance_volume_size
  }

  subnet_id              = aws_subnet.private-a.id
  vpc_security_group_ids = [aws_security_group.private-bastion.id]
  private_ip             = cidrhost(aws_subnet.private-a.cidr_block, 101)

  tags = {
    Name = "${var.prefix}-private-bastion"
  }
}

resource "aws_instance" "windows_bastion" {
  depends_on = [
    aws_internet_gateway.igw
  ]

  ami           = var.windows_instance_ami_id
  instance_type = var.windows_instance_type
  key_name      = aws_key_pair.main.key_name

  root_block_device {
    volume_size = var.windows_instance_volume_size
  }

  subnet_id              = aws_subnet.public-a.id
  vpc_security_group_ids = [aws_security_group.windows.id]
  private_ip             = cidrhost(aws_subnet.public-a.cidr_block, 102)

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

  subnet_id              = aws_subnet.private-c.id
  vpc_security_group_ids = [aws_security_group.gitlab.id]
  private_ip             = cidrhost(aws_subnet.private-c.cidr_block, 101)

  tags = {
    Name = "${var.prefix}-gitlab"
  }
}
resource "aws_security_group" "gitlab" {
  name   = "hognod-gitlab"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      aws_subnet.public-a.cidr_block,
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-b.cidr_block
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      aws_subnet.public-a.cidr_block,
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-b.cidr_block
    ]
  }

  tags = {
    Name = "hognod-gitlab"
  }
}

resource "aws_security_group" "windows" {
  name   = "hognod-windows"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      aws_subnet.public-a.cidr_block,
      aws_subnet.private-a.cidr_block,
      aws_subnet.private-b.cidr_block
    ]
  }

  tags = {
    Name = "hognod-windows"
  }
}

resource "aws_instance" "gitlab" {
  ami           = var.instance_ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.main.key_name
  
  root_block_device {
    volume_size = "50"
  }

  subnet_id = aws_subnet.private-a.id
  vpc_security_group_ids = [ aws_security_group.gitlab.id ]
  private_ip = cidrhost(aws_subnet.private-a.cidr_block, 101)

  tags = {
    Name = "hognod-gitlab"
  }
}

resource "aws_instance" "windows" {
  ami = "ami-045293d19d738a663"
  instance_type = var.instance_type
  key_name = aws_key_pair.main.key_name

  root_block_device {
    volume_size = "50"
  }

  subnet_id = aws_subnet.public-a.id
  vpc_security_group_ids = [
    aws_security_group.windows.id
  ]

  tags = {
    Name = "hognod-windows"
  }
}
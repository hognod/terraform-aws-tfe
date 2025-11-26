resource "aws_db_subnet_group" "main" {
  name = "hognod-db-subnet-group"
  subnet_ids = [
    aws_subnet.private-a.id,
    aws_subnet.private-b.id
  ]

  tags = {
    Name = "hognod-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier = "hognod-rds-cluster"

  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  storage_type          = "gp3"
  storage_encrypted     = false
  allocated_storage     = var.db_storage_size
  max_allocated_storage = 0 # 0: disabled

  multi_az = false

  username = var.db_username
  password = var.db_password
  port     = 5432

  db_subnet_group_name = aws_db_subnet_group.main.name
  publicly_accessible  = false
  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  performance_insights_enabled = false

  enabled_cloudwatch_logs_exports = false
  monitoring_interval             = 0 # 0: disabled

  backup_retention_period = 0
  skip_final_snapshot     = true

  auto_minor_version_upgrade = false
  deletion_protection        = false

  tags = {
    Name = "hognod-rds-cluster"
  }
}
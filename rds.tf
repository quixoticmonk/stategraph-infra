# RDS PostgreSQL
resource "aws_db_subnet_group" "main" {
  name       = "stategraph-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "stategraph-db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier = "stategraph-postgres"

  engine         = "postgres"
  engine_version = "17.2"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "stategraph"
  username = "stategraph"
  password = var.db_password != "" ? var.db_password : random_password.db_password[0].result

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = true

  tags = {
    Name = "stategraph-postgres"
  }
}

# Database password
resource "random_password" "db_password" {
  count   = var.db_password == "" ? 1 : 0
  length  = 16
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

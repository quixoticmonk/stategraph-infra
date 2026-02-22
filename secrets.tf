# Secrets Manager
resource "random_id" "secret_suffix" {
  byte_length = 4
}

resource "aws_secretsmanager_secret" "db_password" {
  name = "stategraph-db-password-${random_id.secret_suffix.hex}"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password != "" ? var.db_password : random_password.db_password[0].result
}


# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "stategraph" {
  name              = "/ecs/stategraph"
  retention_in_days = 7

  tags = {
    Name = "stategraph-logs"
  }
}

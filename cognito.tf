# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "stategraph-users"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  auto_verified_attributes = ["email"]

  tags = {
    Name = "stategraph-user-pool"
  }
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name         = "stategraph-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  callback_urls                        = ["${local.stategraph_url}/oauth2/oidc/callback"]
  logout_urls                          = ["${local.stategraph_url}/logout"]

  supported_identity_providers = ["COGNITO"]
}

# Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "stategraph-${random_string.cognito_domain.result}"
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "random_string" "cognito_domain" {
  length  = 8
  special = false
  upper   = false
}

# Store Cognito client secret in Secrets Manager
resource "aws_secretsmanager_secret" "cognito_client_secret" {
  name = "stategraph/cognito-client-secret-${random_id.secret_suffix.hex}"
}

resource "aws_secretsmanager_secret_version" "cognito_client_secret" {
  secret_id     = aws_secretsmanager_secret.cognito_client_secret.id
  secret_string = aws_cognito_user_pool_client.main.client_secret
}

# Cognito users
resource "aws_cognito_user" "users" {
  for_each = { for user in var.cognito_users : user.username => user }

  user_pool_id = aws_cognito_user_pool.main.id
  username     = each.value.username

  attributes = {
    email          = each.value.email
    email_verified = true
  }

  temporary_password = "TempPass123!"
  message_action     = "SUPPRESS"
}

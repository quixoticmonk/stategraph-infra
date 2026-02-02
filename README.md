<!-- BEGIN_TF_DOCS -->
# StateGraph AWS Infrastructure

Terraform configuration that deploys StateGraph on AWS using ECS EC2 and RDS PostgreSQL.

## Architecture

- **ECS EC2**: Runs the StateGraph container (`ghcr.io/stategraph/stategraph-server`) on EC2 instances
- **CloudFront**: CDN for HTTPS termination and global distribution
- **Application Load Balancer**: Routes traffic to ECS tasks
- **RDS PostgreSQL 17**: Database for state storage and transaction history
- **VPC**: Isolated network with public/private subnets
- **Secrets Manager**: Secure storage for database password and OAuth secrets

## Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.0
3. **Google OAuth Application** - Set up at [Google Cloud Console](https://console.cloud.google.com/)
   - Create OAuth 2.0 Client ID for web application
   - Note the Client ID and Client Secret
4. **StateGraph License Key** - Obtain from [StateGraph](https://stategraph.com/)
5. **Domain name** (optional, can use CloudFront domain)

## Quick Start

1. **Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

2. **Access StateGraph**:
   - Use the `stategraph_url` output value
   - Or configure DNS to point your domain to the load balancer

## Usage

### Basic Configuration

```hcl
module "stategraph" {
  source = "./stategraph-infra"

  # Required variables
  google_oauth_client_id     = "your-google-oauth-client-id"
  google_oauth_client_secret = "your-google-oauth-client-secret"

  # Optional variables
  aws_region         = "us-east-1"
  domain_name        = "stategraph.example.com"
  ecs_desired_count  = 2
  stategraph_version = "latest"
  tags = {
    Environment = "production"
    Project     = "stategraph"
  }
}
```

### Custom Database Configuration

```hcl
module "stategraph" {
  source = "./stategraph-infra"

  # ... other configuration ...

  # Database configuration
  db_instance_class = "db.t3.small"
  db_password       = "your-secure-password"
  # Enable backup
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
}
```

### Production Configuration with Encryption

```hcl
module "stategraph" {
  source = "./stategraph-infra"

  # ... other configuration ...

  # Production settings
  ecs_desired_count = 3
  db_instance_class = "db.r6g.large"
  # Enable encryption
  db_storage_encrypted = true
  db_kms_key_id       = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-ab12-cd34-ef56-abcdef123456"
  tags = {
    Environment = "production"
    Project     = "stategraph"
    Owner       = "platform-team"
  }
}
```

## Configuration

### Environment Variables

The deployment automatically configures these environment variables:

**Required:**
- `STATEGRAPH_UI_BASE`: Public URL for StateGraph
- `DB_HOST`, `DB_USER`, `DB_PASS`, `DB_NAME`: Database connection

**Server Configuration:**
- `STATEGRAPH_PORT`: Internal server port (8180)
- `DB_CONNECT_TIMEOUT`: Database connection timeout (120s)
- `DB_MAX_POOL_SIZE`: Max database connections (100)
- `DB_IDLE_TX_TIMEOUT`: Idle transaction timeout (180s)
- `STATEGRAPH_DB_STATEMENT_TIMEOUT`: Query timeout (1s)

**Logging & Performance:**
- `STATEGRAPH_ACCESS_LOG`: Access logging (/dev/stdout)
- `STATEGRAPH_CLIENT_MAX_BODY_SIZE`: Max request size (512m)

**OAuth Configuration:**
- `STATEGRAPH_OAUTH_TYPE`: OAuth provider (oidc)
- `STATEGRAPH_OAUTH_OIDC_ISSUER_URL`: OIDC issuer URL
- `STATEGRAPH_OAUTH_CLIENT_ID`: OAuth client ID
- `STATEGRAPH_OAUTH_CLIENT_SECRET`: OAuth client secret
- `STATEGRAPH_OAUTH_DISPLAY_NAME`: Login button text
- `STATEGRAPH_OAUTH_REDIRECT_BASE`: OAuth callback base URL

For a complete list of environment variables, see: https://stategraph.com/docs/reference/environment-variables

## StateGraph Image References

- **Main Image**: `ghcr.io/stategraph/stategraph-server:latest`

## Post-Deployment

1. **Access StateGraph**:
   ```bash
   # Get the HTTPS URL (via CloudFront)
   terraform output stategraph_url
   
   # Or get the direct ALB URL (HTTP only)
   terraform output stategraph_alb_url
   ```

2. **DNS Setup** (if using custom domain):
   ```bash
   # Get load balancer details
   terraform output load_balancer_dns
   terraform output load_balancer_zone_id
   
   # Create CNAME or ALIAS record pointing to the load balancer
   ```

3. **OAuth Setup**:
   ```bash
   # Get the OAuth redirect URI for Google Console configuration
   terraform output google_oauth_redirect_uri
   ```

## Scaling

- **Horizontal**: Increase `ecs_desired_count`
- **Vertical**: Increase EC2 instance type in launch template
- **Database**: Upgrade `db_instance_class`

## Cleanup

```bash
terraform destroy
```

## Troubleshooting

### Common Issues

1. **Database Connection Issues**
   - **Check**: Verify security groups allow port 5432 between ECS and RDS
   - **Check**: Confirm RDS instance is in "available" state
   - **Check**: Validate database credentials in Secrets Manager

2. **OAuth Configuration**
   - **Setup**: Configure Google OAuth at [Google Cloud Console](https://console.cloud.google.com/)
   - **Redirect URI**: Use the `google_oauth_redirect_uri` output value
   - **Documentation**: See [StateGraph OAuth docs](https://stategraph.com/docs/authentication/google-oauth)

3. **Load Balancer Health Checks**
   - **Check**: Target group health in AWS Console
   - **Port**: Ensure health checks target the correct container port (8080)
   - **Path**: Health check endpoint is `/api/v1/health`

### Monitoring

- **CloudWatch Logs**: `/ecs/stategraph`
- **ECS Service Events**: Check service events for deployment issues
- **Target Group Health**: Monitor ALB target group for unhealthy targets

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.28.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.28.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.8.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_cloudfront_distribution.stategraph](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudwatch_log_group.stategraph](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_db_instance.postgres](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_subnet_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_ecs_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_service.stategraph](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.stategraph](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_iam_instance_profile.ecs_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.ecs_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ecs_instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.secrets_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ecs_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ecs_instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ecs_instance_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_internet_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_launch_template.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_lb.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.stategraph](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.stategraph](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_nat_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_secretsmanager_secret.db_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.google_client_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.db_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.google_client_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.ecs_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.vpc_endpoints](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.ecr_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.ecr_dkr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [random_id.secret_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_password.db_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_ami.ecs_optimized](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | `"us-east-1"` | no |
| <a name="input_db_instance_class"></a> [db\_instance\_class](#input\_db\_instance\_class) | RDS instance class | `string` | `"db.t3.micro"` | no |
| <a name="input_db_password"></a> [db\_password](#input\_db\_password) | Password for PostgreSQL database (leave empty to auto-generate) | `string` | `""` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for StateGraph (optional - will use ALB DNS if not provided) | `string` | `""` | no |
| <a name="input_ecs_desired_count"></a> [ecs\_desired\_count](#input\_ecs\_desired\_count) | Desired number of ECS tasks | `number` | `1` | no |
| <a name="input_google_oauth_client_id"></a> [google\_oauth\_client\_id](#input\_google\_oauth\_client\_id) | Google OAuth Client ID | `string` | n/a | yes |
| <a name="input_google_oauth_client_secret"></a> [google\_oauth\_client\_secret](#input\_google\_oauth\_client\_secret) | Google OAuth Client Secret | `string` | n/a | yes |
| <a name="input_stategraph_version"></a> [stategraph\_version](#input\_stategraph\_version) | StateGraph Docker image version | `string` | `"latest"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | <pre>{<br/>  "environment": "dev",<br/>  "solution": "stategraph"<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudfront_domain"></a> [cloudfront\_domain](#output\_cloudfront\_domain) | CloudFront distribution domain name |
| <a name="output_db_password"></a> [db\_password](#output\_db\_password) | Database password (auto-generated if not provided) |
| <a name="output_ecs_cluster_name"></a> [ecs\_cluster\_name](#output\_ecs\_cluster\_name) | Name of the ECS cluster |
| <a name="output_google_oauth_redirect_uri"></a> [google\_oauth\_redirect\_uri](#output\_google\_oauth\_redirect\_uri) | Google OAuth redirect URI to configure in Google Console |
| <a name="output_load_balancer_dns"></a> [load\_balancer\_dns](#output\_load\_balancer\_dns) | DNS name of the load balancer |
| <a name="output_load_balancer_zone_id"></a> [load\_balancer\_zone\_id](#output\_load\_balancer\_zone\_id) | Zone ID of the load balancer |
| <a name="output_rds_endpoint"></a> [rds\_endpoint](#output\_rds\_endpoint) | RDS instance endpoint |
| <a name="output_stategraph_alb_url"></a> [stategraph\_alb\_url](#output\_stategraph\_alb\_url) | Direct ALB URL (HTTP only) |
| <a name="output_stategraph_url"></a> [stategraph\_url](#output\_stategraph\_url) | URL to access StateGraph (HTTPS via CloudFront) |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC |
<!-- END_TF_DOCS -->
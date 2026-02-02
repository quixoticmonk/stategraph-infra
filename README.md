# StateGraph AWS Infrastructure

This Terraform configuration deploys StateGraph on AWS using ECS EC2 and RDS PostgreSQL.

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

3. **Access StateGraph**:
   - Use the `stategraph_url` output value
   - Or configure DNS to point your domain to the load balancer

## Configuration

### Required Variables

- `google_oauth_client_id`: Google OAuth Client ID
- `google_oauth_client_secret`: Google OAuth Client Secret  
- `stategraph_license_key`: StateGraph license key

### Optional Variables

- `aws_region`: AWS region (default: us-east-1)
- `domain_name`: Your domain name for StateGraph (optional, uses CloudFront domain if not provided)
- `db_password`: Secure password for PostgreSQL (auto-generated if not provided)
- `db_instance_class`: RDS instance size (default: db.t3.micro)
- `ecs_desired_count`: Number of ECS tasks (default: 1)
- `stategraph_version`: Docker image version (default: 0.1.16)

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

- **Main Image**: `ghcr.io/stategraph/stategraph-server:0.1.16`

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

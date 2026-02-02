output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "stategraph_url" {
  description = "URL to access StateGraph (HTTPS via CloudFront)"
  value       = "https://${aws_cloudfront_distribution.stategraph.domain_name}"
}

output "stategraph_alb_url" {
  description = "Direct ALB URL (HTTP only)"
  value       = local.stategraph_url
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.stategraph.domain_name
}

output "google_oauth_redirect_uri" {
  description = "Google OAuth redirect URI to configure in Google Console"
  value       = "https://${aws_cloudfront_distribution.stategraph.domain_name}/oauth2/oidc/callback"
}

output "db_password" {
  description = "Database password (auto-generated if not provided)"
  value       = var.db_password != "" ? "Custom password provided" : random_password.db_password[0].result
  sensitive   = true
}

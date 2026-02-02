locals {
  stategraph_url = var.domain_name != "" ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.stategraph.domain_name}"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

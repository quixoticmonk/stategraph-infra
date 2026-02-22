locals {
  stategraph_url      = var.domain_name != "" ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.stategraph.domain_name}"
  my_ip_cidr          = "${chomp(data.http.my_ip.response_body)}/32"
  allowed_cidr_blocks = length(var.allowed_cidr_blocks) > 0 ? var.allowed_cidr_blocks : [local.my_ip_cidr]
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

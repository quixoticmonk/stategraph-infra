terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.28.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      solution    = "stategraph"
      environment = "dev"
    }
  }
}

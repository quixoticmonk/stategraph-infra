variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Domain name for StateGraph (optional - will use ALB DNS if not provided)"
  type        = string
  default     = ""
}

variable "db_password" {
  description = "Password for PostgreSQL database (leave empty to auto-generate)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "stategraph_version" {
  description = "StateGraph Docker image version"
  type        = string
  default     = "latest"
}


variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    solution    = "stategraph"
    environment = "dev"
  }
}
variable "cognito_users" {
  description = "List of users to create in Cognito"
  type = list(object({
    username = string
    email    = string
  }))
  default = [
    {
      username = "admin@example.com"
      email    = "admin@example.com"
    }
  ]
}

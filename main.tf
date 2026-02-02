# IAM Roles
resource "aws_iam_role" "ecs_instance_role" {
  name = "stategraph-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ssm" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "stategraph-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_iam_role" "ecs_execution" {
  name = "stategraph-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "secrets_access" {
  name = "stategraph-secrets-access"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.db_password.arn,
          aws_secretsmanager_secret.google_client_secret.arn
        ]
      }
    ]
  })
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "stategraph"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "stategraph-cluster"
  }
}

# Launch Template for ECS EC2 instances
resource "aws_launch_template" "ecs" {
  name_prefix   = "stategraph-ecs-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t3.medium"

  vpc_security_group_ids = [aws_security_group.ecs_instance.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "stategraph-ecs-instance"
    }
  }
}

# Auto Scaling Group for ECS instances
resource "aws_autoscaling_group" "ecs" {
  name                = "stategraph-ecs-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "stategraph-ecs-instance"
    propagate_at_launch = true
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "stategraph" {
  family                   = "stategraph"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name  = "stategraph"
      image = "ghcr.io/stategraph/stategraph-server:${var.stategraph_version}"

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 0
          protocol      = "tcp"
        }
      ]

      memory = 1024
      
      environment = [
        {
          name  = "STATEGRAPH_UI_BASE"
          value = local.stategraph_url
        },
        {
          name  = "LICENSE_KEY"
          value = var.stategraph_license_key
        },
        {
          name  = "STATEGRAPH_OAUTH_TYPE"
          value = "oidc"
        },
        {
          name  = "STATEGRAPH_OAUTH_OIDC_ISSUER_URL"
          value = "https://accounts.google.com"
        },
        {
          name  = "STATEGRAPH_OAUTH_CLIENT_ID"
          value = var.google_oauth_client_id
        },
        {
          name  = "STATEGRAPH_OAUTH_DISPLAY_NAME"
          value = "Sign in with Google"
        },
        {
          name  = "STATEGRAPH_OAUTH_REDIRECT_BASE"
          value = local.stategraph_url
        },
        {
          name  = "DB_HOST"
          value = split(":", aws_db_instance.postgres.endpoint)[0]
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "DB_USER"
          value = "stategraph"
        },
        {
          name  = "DB_NAME"
          value = "stategraph"
        },
        {
          name  = "DB_PASS"
          valueFrom = aws_secretsmanager_secret.db_password.arn
        },
        {
          name  = "STATEGRAPH_OAUTH_CLIENT_SECRET"
          value = var.google_oauth_client_secret
        },
        {
          name  = "STATEGRAPH_ENABLE_CORS"
          value = "true"
        },
        {
          name  = "STATEGRAPH_PORT"
          value = "8180"
        },
        {
          name  = "DB_CONNECT_TIMEOUT"
          value = "120"
        },
        {
          name  = "DB_MAX_POOL_SIZE"
          value = "100"
        },
        {
          name  = "DB_IDLE_TX_TIMEOUT"
          value = "180s"
        },
        {
          name  = "STATEGRAPH_DB_STATEMENT_TIMEOUT"
          value = "1s"
        },
        {
          name  = "STATEGRAPH_ACCESS_LOG"
          value = "/dev/stdout"
        },
        {
          name  = "STATEGRAPH_CLIENT_MAX_BODY_SIZE"
          value = "512m"
        }
      ]

      healthCheck = {
        command = ["CMD-SHELL", "curl -f http://localhost:8080/api/v1/health || exit 1"]
        interval = 30
        timeout = 5
        retries = 3
        startPeriod = 120
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.stategraph.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "stategraph"
        }
      }
    }
  ])

  tags = {
    Name = "stategraph-task"
  }
}

# ECS Service
resource "aws_ecs_service" "stategraph" {
  name            = "stategraph"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.stategraph.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = aws_lb_target_group.stategraph.arn
    container_name   = "stategraph"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.stategraph, aws_autoscaling_group.ecs]

  tags = {
    Name = "stategraph-service"
  }
}

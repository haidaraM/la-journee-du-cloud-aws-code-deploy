locals {
  app_port = 8000
  task_environment_variables = [
    {
      name  = "APP_PORT"
      value = tostring(local.app_port)
    },
    {
      name  = "ALLOWED_HOSTS"
      value = "*"
    },
    {
      name  = "DEBUG"
      value = "False"
    },
    {
      name  = "STATIC_USE_S3"
      value = "True"
    },
    {
      name  = "STATIC_ENDPOINT_URL"
      value = "https://${aws_s3_bucket.static.bucket_regional_domain_name}"
    },
    {
      name  = "STATIC_BUCKET_NAME"
      value = aws_s3_bucket.static.bucket
    },
    {
      name  = "STATIC_REGION_NAME"
      value = var.aws_region
    },
    {
      name  = "ERROR_PERCENTAGE"
      value = "0"
    },
    {
      name  = "VERSION"
      value = var.app_image.tag
    }
  ]
  task_secrets = [
    # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/secrets-envvar-secrets-manager.html
    {
      "name" : "SECRET_KEY",
      "valueFrom" : "${aws_secretsmanager_secret.secrets.arn}:secret_key::"
    },
    {
      "name" : "DB_HOST",
      "valueFrom" : "${aws_secretsmanager_secret.secrets.arn}:db_host::"
    },
    {
      "name" : "DB_NAME",
      "valueFrom" : "${aws_secretsmanager_secret.secrets.arn}:db_name::"
    },
    {
      "name" : "DB_USER",
      "valueFrom" : "${aws_secretsmanager_secret.secrets.arn}:db_user::"
    },
    {
      "name" : "DB_PASS",
      "valueFrom" : "${aws_secretsmanager_secret.secrets.arn}:db_pass::"
    },
    {
      "name" : "DB_PORT",
      "valueFrom" : "${aws_secretsmanager_secret.secrets.arn}:db_port::"
    },
    {
      "name" : "DB_ENGINE",
      "valueFrom" : "${aws_secretsmanager_secret.secrets.arn}:db_engine::"
    }
  ]
}

resource "aws_ecs_cluster" "this" {
  name = "${var.prefix}-ecs-cluster"
}



resource "aws_security_group" "api" {
  name        = "${var.prefix}-ecs-api"
  description = "Security group of the ECS API service"
  vpc_id      = var.vpc_id
  tags = {
    Name = "${var.prefix}-ecs-api"
  }

  egress {
    description = "To anywhere"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "Allow from ALB"
    from_port       = local.app_port
    protocol        = "TCP"
    to_port         = local.app_port
    security_groups = [aws_security_group.alb.id]
  }
}


resource "aws_ecs_service" "this_api" {
  name            = "${var.prefix}-api"
  desired_count   = 1
  task_definition = aws_ecs_task_definition.this_api.arn

  cluster          = aws_ecs_cluster.this.id
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  propagate_tags = "SERVICE"

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    container_name   = "api"
    container_port   = local.app_port
    target_group_arn = aws_alb_target_group.api["blue"].arn
  }

  network_configuration {
    security_groups  = [aws_security_group.api.id]
    assign_public_ip = false
    subnets          = var.private_subnet_ids
  }

  depends_on = [aws_alb_listener_rule.rules]

  lifecycle {
    ignore_changes = [
      # Champs gérés par CodeDeploy
      task_definition,
      load_balancer
    ]
  }
}

resource "aws_ecs_task_definition" "this_api" {
  family                   = "${var.prefix}-api"
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
  requires_compatibilities = ["FARGATE"]
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html
  network_mode = "awsvpc"
  cpu          = "512"
  memory       = "1024"
  track_latest = true
  container_definitions = jsonencode([
    {
      name        = "api"
      image       = "${var.app_image.name}:${var.app_image.tag}"
      essential   = true
      environment = local.task_environment_variables
      secrets     = local.task_secrets
      command = [
        "/bin/sh", "-c", "gunicorn --timeout 300 --log-file - demoljdc.wsgi:application --bind :${local.app_port}"
      ]
      portMappings = [
        {
          containerPort = local.app_port
          protocol      = "tcp"
        }
      ]
      logConfiguration : {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.api_logs.name,
          "awslogs-region"        = var.aws_region,
          "awslogs-stream-prefix" = "task"
        }
      },
    }
  ])
}

resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "${var.prefix}-api"
  retention_in_days = 7
}

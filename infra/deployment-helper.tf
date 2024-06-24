resource "aws_ecs_task_definition" "deployment_helper" {
  family                   = "${var.prefix}-api-deployment-helper"
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  track_latest             = true

  container_definitions = jsonencode([
    {
      name        = "deployment-helper"
      image       = "${var.app_image.name}:${var.app_image.tag}"
      environment = local.task_environment_variables
      secrets     = local.task_secrets
      command     = ["/bin/ash", "collect-and-migrate.sh"]
      logConfiguration : {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.deployment_helper.name,
          "awslogs-region"        = var.aws_region,
          "awslogs-stream-prefix" = "task"
        }
      },
    }
  ])
}

resource "aws_cloudwatch_log_group" "deployment_helper" {
  name              = "${var.prefix}-api-deployment-helper"
  retention_in_days = 7
}

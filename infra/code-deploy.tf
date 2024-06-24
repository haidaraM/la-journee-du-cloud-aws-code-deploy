locals {
  # https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-example.html
  app_spec_content = jsonencode({
    version : "0.0",
    Resources : [
      {
        TargetService : {
          Type : "AWS::ECS::Service",
          Properties : {
            TaskDefinition : aws_ecs_task_definition.this_api.arn
            LoadBalancerInfo : {
              ContainerName : "api",
              ContainerPort : local.app_port
            }
            PlatformVersion : aws_ecs_service.this_api.platform_version
            NetworkConfiguration : {
              AwsvpcConfiguration : {
                Subnets : var.private_subnet_ids,
                SecurityGroups : [aws_security_group.api.id],
                AssignPublicIp : "DISABLED"
              }
            }
          }
        }
      }
    ]
  })

  code_deploy_args = templatefile("${path.module}/templates/code-deploy-args-template.json", {
    applicationName      = aws_codedeploy_app.this.name
    deploymentGroupName  = aws_codedeploy_deployment_group.this.deployment_group_name
    appSpecContent       = replace(local.app_spec_content, "\"", "\\\"")
    appSpecContentSha256 = sha256(local.app_spec_content)
    description          = "Version ${var.app_image.tag} with task definition revision ${aws_ecs_task_definition.this_api.revision}"
  })

  code_deploy_args_output = "${path.module}/out/code-deploy-args.json"

}

resource "aws_codedeploy_app" "this" {
  name             = "${var.prefix}-api"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_config" "demo" {
  deployment_config_name = "${var.prefix}-demo-25percent"
  compute_platform       = "ECS"

  traffic_routing_config {
    type = "TimeBasedLinear"
    time_based_linear {
      interval   = 1 # minute
      percentage = 25
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_codedeploy_deployment_group" "this" {
  app_name               = aws_codedeploy_app.this.name
  deployment_group_name  = "${var.prefix}-api"
  deployment_config_name = aws_codedeploy_deployment_config.demo.deployment_config_name
  service_role_arn       = aws_iam_role.code_deploy.arn

  /**
  Auto roll back configuration
   */
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM", "DEPLOYMENT_STOP_ON_REQUEST"]
  }

  alarm_configuration {
    enabled                   = true
    ignore_poll_alarm_failure = false
    alarms = [
      aws_cloudwatch_metric_alarm.http_5xx["blue"].alarm_name,
      aws_cloudwatch_metric_alarm.http_5xx["green"].alarm_name
    ]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = "STOP_DEPLOYMENT"
      wait_time_in_minutes = 10
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.this.name
    service_name = aws_ecs_service.this_api.name
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [
          aws_lb_listener.listeners["live"].arn
        ]
      }

      test_traffic_route {
        listener_arns = [
          aws_lb_listener.listeners["test"].arn
        ]
      }

      target_group {
        name = aws_alb_target_group.api["blue"].name
      }

      target_group {
        name = aws_alb_target_group.api["green"].name
      }
    }
  }


  depends_on = [
    # These policies need to be created before the deployment group and deleted after
    aws_iam_role_policy_attachment.code_deploy_default_policy,
    aws_iam_role_policy.code_deploy_pass_role,
  ]
}

resource "aws_iam_role" "code_deploy" {
  name               = "${var.prefix}-code-deploy"
  description        = "Rôle de service CodeDeploy pour les déploiements ECS pour l'application ${aws_codedeploy_app.this.name}"
  assume_role_policy = data.aws_iam_policy_document.code_deploy_assume_role.json
}

resource "aws_iam_role_policy_attachment" "code_deploy_default_policy" {
  role       = aws_iam_role.code_deploy.id
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECSLimited"
  # might need to replace this with a custom policy at some point
}

resource "aws_iam_role_policy" "code_deploy_pass_role" {
  name   = "code-deploy-pass-role"
  role   = aws_iam_role.code_deploy.id
  policy = data.aws_iam_policy_document.code_deploy_pass_role.json
}

resource "terraform_data" "app_spec" {
  triggers_replace = [
    local.code_deploy_args,
    local.code_deploy_args_output
  ]

  provisioner "local-exec" {
    command = "echo '${local.code_deploy_args}' > ${local.code_deploy_args_output}"
  }
}

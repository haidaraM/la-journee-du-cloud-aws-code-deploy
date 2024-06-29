locals {
  subnet_ids = join(",", var.private_subnet_ids)
}

output "deployment_helper_commands" {
  description = "Commandes pour deployer le code"
  value = [
    "aws ecs run-task --launch-type FARGATE --cluster ${aws_ecs_cluster.this.name} --task-definition ${aws_ecs_task_definition.deployment_helper.arn} --network-configuration 'awsvpcConfiguration={subnets=[${local.subnet_ids}],securityGroups=[${aws_security_group.api.id}],assignPublicIp=DISABLED}'  --query 'tasks[0].taskArn' --output text",
    "aws ecs wait tasks-stopped --cluster ${aws_ecs_cluster.this.name} --tasks $(aws ecs list-tasks --cluster ${aws_ecs_cluster.this.name} --desired-status STOPPED --family ${aws_ecs_task_definition.deployment_helper.family} --query 'taskArns' --output text)"
  ]
}

output "api_url" {
  description = "API URL"
  value       = "http://${aws_alb.app.dns_name}/admin"
}

output "logs_groups_tail_commands" {
  description = "Commandes pour consulter les logs des services"
  value = {
    api               = "aws logs tail --follow --format short --since 1m ${aws_cloudwatch_log_group.api_logs.name}"
    deployment_helper = "aws logs tail --follow --format short --since 1m ${aws_cloudwatch_log_group.deployment_helper.name}"
  }
}

output "code_deploy_command" {
  description = "Commande pour deployer le code via CodeDeploy"
  value       = "aws deploy create-deployment --cli-input-json file://${local.code_deploy_args_output} --region ${var.aws_region}"
}
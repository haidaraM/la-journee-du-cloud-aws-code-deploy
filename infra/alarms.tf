resource "aws_cloudwatch_metric_alarm" "http_5xx" {
  for_each            = toset(["blue", "green"])
  alarm_name          = "${var.prefix}-api-http-5xx-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  alarm_description   = "Alarme si le nombre de réponses HTTP 5xx est supérieur à 0"
  threshold           = 0
  period              = 60
  evaluation_periods  = 1
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_Target_5XX_Count"

  dimensions = {
    LoadBalancer = aws_alb.app.arn_suffix
    TargetGroup  = aws_alb_target_group.api[each.key].arn_suffix
  }
}

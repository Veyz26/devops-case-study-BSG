resource "aws_cloudwatch_dashboard" "ops_dashboard" {
  dashboard_name = "${var.project}-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x = 0,
        y = 0,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.cluster.name]
          ],
          period = 60,
          stat   = "Average",
          title  = "ECS CPU Utilization",
          region = "af-south-1",
          annotations = {}
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project}-HighCPUAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "Triggered when CPU > 90%"
  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
  }
}
module "teams_webhook" {
  count             = var.teams_webhook_url != "" ? 1 : 0
  source            = "./module/LAMBDA/SNS-TEAMS-WEBHOOK"
  sns_topic_arns    = { for region, topic in aws_sns_topic.connect_alarms : region => topic.arn }
  teams_webhook_url = var.teams_webhook_url
}

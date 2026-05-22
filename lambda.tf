module "teams_webhook" {
  count             = var.teams_webhook_url != "" ? 1 : 0
  source            = "./module/LAMBDA/SNS-TEAMS-WEBHOOK"
  sns_topic_arn     = aws_sns_topic.connect_alarms.arn
  teams_webhook_url = var.teams_webhook_url
}

module "cloudwatch_dashboard" {
  source         = "./module/CLOUDWATCH/CLOUDWATCH-DASHBOARD"
  for_each       = local.dashboards
  dashboard_name = each.value["dashboard_name"]
  dashboard_body = each.value["dashboard_body"]
  instance_id    = each.value["instance_id"]
  instance_alias = each.value["instance_alias"]
  sns_topic_arn  = aws_sns_topic.connect_alarms.arn
}    
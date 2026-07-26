# One alarm topic per configured region: CloudWatch alarm actions can only
# target an SNS topic in the alarm's own region.
resource "aws_sns_topic" "connect_alarms" {
  for_each = toset(var.aws_regions)
  region   = each.value
  name     = "connect-cloudwatch-alarms"
}

resource "aws_sns_topic_subscription" "alarm_email" {
  for_each  = var.alarm_email != "" ? toset(var.aws_regions) : toset([])
  region    = each.value
  topic_arn = aws_sns_topic.connect_alarms[each.value].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

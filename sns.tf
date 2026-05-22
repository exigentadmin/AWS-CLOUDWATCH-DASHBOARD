resource "aws_sns_topic" "connect_alarms" {
  name = "connect-cloudwatch-alarms"
}

resource "aws_sns_topic_subscription" "alarm_email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.connect_alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

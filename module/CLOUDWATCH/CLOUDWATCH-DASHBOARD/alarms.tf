locals {
  voice_dimensions = {
    InstanceId  = var.instance_id
    MetricGroup = "VoiceCalls"
  }
}

resource "aws_cloudwatch_metric_alarm" "concurrent_calls_pct" {
  region              = var.region
  alarm_name          = "${var.instance_alias}-concurrent-calls-pct"
  alarm_description   = "Concurrent calls percentage exceeds 80% for ${var.instance_alias}"
  namespace           = "AWS/Connect"
  metric_name         = "ConcurrentCallsPercentage"
  dimensions          = local.voice_dimensions
  statistic           = "Maximum"
  period              = 900
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "missed_calls" {
  region              = var.region
  alarm_name          = "${var.instance_alias}-missed-calls"
  alarm_description   = "More than 5 missed calls in the past hour for ${var.instance_alias}"
  namespace           = "AWS/Connect"
  metric_name         = "MissedCalls"
  dimensions          = local.voice_dimensions
  statistic           = "Sum"
  period              = 3600
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "calls_breaching_quota" {
  region              = var.region
  alarm_name          = "${var.instance_alias}-calls-breaching-quota"
  alarm_description   = "Calls exceeding concurrency quota for ${var.instance_alias}"
  namespace           = "AWS/Connect"
  metric_name         = "CallsBreachingConcurrencyQuota"
  dimensions          = local.voice_dimensions
  statistic           = "Sum"
  period              = 900
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "throttled_calls" {
  region              = var.region
  alarm_name          = "${var.instance_alias}-throttled-calls"
  alarm_description   = "Throttled calls detected for ${var.instance_alias}"
  namespace           = "AWS/Connect"
  metric_name         = "ThrottledCalls"
  dimensions          = local.voice_dimensions
  statistic           = "Sum"
  period              = 900
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "packet_loss_rate" {
  region              = var.region
  alarm_name          = "${var.instance_alias}-packet-loss-rate"
  alarm_description   = "Average packet loss rate exceeds 1% for ${var.instance_alias}"
  namespace           = "AWS/Connect"
  metric_name         = "PacketLossRate"
  dimensions          = local.voice_dimensions
  statistic           = "Average"
  period              = 900
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 1
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "contact_flow_errors" {
  region              = var.region
  alarm_name          = "${var.instance_alias}-contact-flow-errors"
  alarm_description   = "More than 5 contact flow errors in the past hour for ${var.instance_alias}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 5
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  metric_query {
    id          = "total_errors"
    period      = 3600
    expression  = "SELECT SUM(ContactFlowErrors) FROM SCHEMA(\"AWS/Connect\", InstanceId, MetricGroup, ContactFlowName) WHERE InstanceId = '${var.instance_id}'"
    label       = "Total Contact Flow Errors"
    return_data = true
  }
}

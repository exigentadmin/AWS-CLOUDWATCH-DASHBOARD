variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
  default     = "connect-alarms-teams-webhook"
}

variable "teams_webhook_url" {
  description = "Microsoft Teams incoming webhook URL to post alarm notifications to."
  type        = string
  sensitive   = true
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic to subscribe to."
  type        = string
}

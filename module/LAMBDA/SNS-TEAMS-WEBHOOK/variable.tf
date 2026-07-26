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

variable "sns_topic_arns" {
  description = "Map of region to SNS topic ARN. The Lambda is subscribed to every topic; SNS delivers to Lambda across regions."
  type        = map(string)
}

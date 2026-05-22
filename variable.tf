variable "instance_aliases" {
  description = "Optional list of Connect instance aliases to create dashboards for. Leave empty to create dashboards for every instance discovered across all configured regions."
  type        = list(string)
  default     = []
}

variable "log_bucket_name" {
  description = "Name of an existing S3 bucket to use for CloudWatch log exports. Leave empty to auto-create a new bucket with a 2-year retention lifecycle."
  type        = string
  default     = ""
}

variable "alarm_email" {
  description = "Email address to subscribe to the CloudWatch alarms SNS topic. Leave empty to create the topic without a subscription."
  type        = string
  default     = ""
}

variable "teams_webhook_url" {
  description = "Microsoft Teams incoming webhook URL for alarm notifications. Leave empty to skip Lambda deployment."
  type        = string
  default     = ""
  sensitive   = true
}

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

variable "python_command" {
  description = "Command used to run the instance-discovery script. Use \"python3\" on Linux/macOS or \"python\" on Windows."
  type        = string
  default     = "python3"
}

variable "aws_regions" {
  description = "AWS regions to scan for Amazon Connect instances and permit for CloudWatch Logs exports."
  type        = list(string)
  default     = ["us-east-1", "us-west-2"]

  validation {
    condition     = length(var.aws_regions) > 0
    error_message = "aws_regions must contain at least one region."
  }
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

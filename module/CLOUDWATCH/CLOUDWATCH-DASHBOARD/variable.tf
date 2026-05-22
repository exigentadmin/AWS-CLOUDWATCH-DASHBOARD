variable "dashboard_name" {
  description = "Dashboard name"
  type        = string
}

variable "dashboard_body" {
  description = "Dashboard body"
  type        = string
}

variable "instance_id" {
  description = "Amazon Connect instance ID"
  type        = string
}

variable "instance_alias" {
  description = "Amazon Connect instance alias"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic to notify when an alarm triggers or recovers"
  type        = string
}
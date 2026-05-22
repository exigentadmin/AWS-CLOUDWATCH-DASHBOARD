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

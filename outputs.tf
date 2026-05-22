output "dashboard_names" {
  description = "Names of all CloudWatch dashboards created."
  value       = [for k, v in module.cloudwatch_dashboard : v.dashboard_name]
}

output "dashboard_arns" {
  description = "Map of dashboard key to ARN, suitable for use in IAM policies or cross-module references."
  value       = { for k, v in module.cloudwatch_dashboard : k => v.dashboard_arn }
}

output "alarm_sns_topic_arn" {
  description = "ARN of the SNS topic used for CloudWatch alarm notifications."
  value       = aws_sns_topic.connect_alarms.arn
}

output "log_bucket_name" {
  description = "Name of the S3 bucket used for CloudWatch log exports."
  value       = local.log_bucket_id
}

output "log_bucket_arn" {
  description = "ARN of the S3 bucket used for CloudWatch log exports."
  value       = local.log_bucket_arn
}

output "teams_webhook_lambda_arn" {
  description = "ARN of the Teams webhook Lambda function. Empty if teams_webhook_url was not set."
  value       = length(module.teams_webhook) > 0 ? module.teams_webhook[0].lambda_arn : null
}

output "discovered_instances" {
  description = "Map of Connect instance alias to { id, region } discovered across all configured regions."
  value       = local.all_instances
}

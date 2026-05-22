output "lambda_arn" {
  description = "ARN of the Teams webhook Lambda function."
  value       = aws_lambda_function.teams_webhook.arn
}

output "lambda_function_name" {
  description = "Name of the Teams webhook Lambda function."
  value       = aws_lambda_function.teams_webhook.function_name
}

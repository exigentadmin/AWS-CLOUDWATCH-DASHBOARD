resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = var.dashboard_name
  dashboard_body = var.dashboard_body
}
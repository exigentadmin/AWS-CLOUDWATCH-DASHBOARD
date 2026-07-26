data "archive_file" "handler" {
  type        = "zip"
  source_file = "${path.module}/src/handler.py"
  output_path = "${path.module}/handler.zip"
}

resource "aws_iam_role" "lambda" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "teams_webhook" {
  function_name    = var.function_name
  role             = aws_iam_role.lambda.arn
  filename         = data.archive_file.handler.output_path
  source_code_hash = data.archive_file.handler.output_base64sha256
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 10

  environment {
    variables = {
      TEAMS_WEBHOOK_URL = var.teams_webhook_url
    }
  }
}

resource "aws_lambda_permission" "sns" {
  for_each      = var.sns_topic_arns
  statement_id  = "AllowSNSInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.teams_webhook.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = each.value
}

# The subscription must be created in each topic's region.
resource "aws_sns_topic_subscription" "lambda" {
  for_each  = var.sns_topic_arns
  region    = each.key
  topic_arn = each.value
  protocol  = "lambda"
  endpoint  = aws_lambda_function.teams_webhook.arn
}

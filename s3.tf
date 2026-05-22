resource "random_id" "log_bucket" {
  count       = local.create_log_bucket ? 1 : 0
  byte_length = 4
}

resource "aws_s3_bucket" "cloudwatch_logs" {
  count  = local.create_log_bucket ? 1 : 0
  bucket = local.effective_log_bucket_name
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudwatch_logs" {
  count  = local.create_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.cloudwatch_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "cloudwatch_logs" {
  count  = local.create_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.cloudwatch_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudwatch_logs" {
  count  = local.create_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.cloudwatch_logs[0].id

  depends_on = [aws_s3_bucket_versioning.cloudwatch_logs]

  rule {
    id     = "two-year-retention"
    status = "Enabled"

    filter {}

    expiration {
      days = 730
    }

    noncurrent_version_expiration {
      noncurrent_days = 730
    }
  }
}

# Allows CloudWatch Logs export tasks from both configured regions to write to the bucket.
data "aws_iam_policy_document" "cloudwatch_logs_s3" {
  statement {
    sid    = "AllowCloudWatchLogsGetAcl"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.us-east-1.amazonaws.com", "logs.us-west-2.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::${local.effective_log_bucket_name}"]
  }

  statement {
    sid    = "AllowCloudWatchLogsPutObject"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.us-east-1.amazonaws.com", "logs.us-west-2.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.effective_log_bucket_name}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudwatch_logs" {
  count  = local.create_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.cloudwatch_logs[0].id
  policy = data.aws_iam_policy_document.cloudwatch_logs_s3.json
}

# Reference an externally-managed bucket when log_bucket_name is provided in tfvars.
data "aws_s3_bucket" "existing_log_bucket" {
  count  = local.create_log_bucket ? 0 : 1
  bucket = var.log_bucket_name
}

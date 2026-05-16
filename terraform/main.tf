terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3     = "http://s3.localhost.localstack.cloud:4566"
    lambda = "http://localhost:4566"
    iam    = "http://localhost:4566"
    sns    = "http://localhost:4566"
    sts    = "http://localhost:4566"
    logs   = "http://localhost:4566"
  }
}

# ---------------------------------------------------------------------------
# S3 buckets: source (s3-start) and destination (s3-finish)
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "start" {
  bucket        = "s3-start"
  force_destroy = true
}

resource "aws_s3_bucket" "finish" {
  bucket        = "s3-finish"
  force_destroy = true
}

# ---------------------------------------------------------------------------
# S3 lifecycle policy: expire old objects in s3-finish after 30 days
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "finish_lifecycle" {
  bucket = aws_s3_bucket.finish.id

  rule {
    id     = "expire-old-objects"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# ---------------------------------------------------------------------------
# SNS topic for notifications about copied files
# ---------------------------------------------------------------------------
resource "aws_sns_topic" "file_copied" {
  name = "file-copied-topic"
}

# ---------------------------------------------------------------------------
# IAM role for Lambda
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda-copy-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [aws_s3_bucket.start.arn, "${aws_s3_bucket.start.arn}/*"]
  }
  statement {
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.finish.arn}/*"]
  }
  statement {
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.file_copied.arn]
  }
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda-copy-policy"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

# ---------------------------------------------------------------------------
# Lambda function: copies the uploaded object to s3-finish and notifies SNS
# ---------------------------------------------------------------------------
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/build/lambda.zip"
}

resource "aws_lambda_function" "copy_file" {
  function_name    = "copy-file-lambda"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30

  environment {
    variables = {
      DEST_BUCKET         = aws_s3_bucket.finish.bucket
      SNS_TOPIC           = aws_sns_topic.file_copied.arn
      LOCALSTACK_ENDPOINT = "http://localhost.localstack.cloud:4566"
    }
  }
}

# ---------------------------------------------------------------------------
# Allow S3 to invoke Lambda + S3 -> Lambda notification
# ---------------------------------------------------------------------------
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.copy_file.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.start.arn
}

resource "aws_s3_bucket_notification" "start_notification" {
  bucket = aws_s3_bucket.start.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.copy_file.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

output "start_bucket" {
  value = aws_s3_bucket.start.bucket
}

output "finish_bucket" {
  value = aws_s3_bucket.finish.bucket
}

output "lambda_name" {
  value = aws_lambda_function.copy_file.function_name
}

output "sns_topic_arn" {
  value = aws_sns_topic.file_copied.arn
}

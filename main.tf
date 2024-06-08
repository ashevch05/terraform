terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

resource "aws_s3_bucket" "s3_start" {
  provider = aws.localstack
  bucket   = "s3-start"
}

resource "aws_s3_bucket" "s3_finish" {
  provider = aws.localstack
  bucket   = "s3-finish"
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_start_lifecycle" {
  provider = aws.localstack
  bucket   = aws_s3_bucket.s3_start.id

  rule {
    id     = "Move to Glacier"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  provider = aws.localstack
  name     = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  provider  = aws.localstack
  role      = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}

resource "aws_lambda_function" "s3_copy_lambda" {
  provider          = aws.localstack
  filename          = "lambda_function.zip"
  function_name     = "s3_copy_function"
  role              = aws_iam_role.lambda_exec_role.arn
  handler           = "lambda_function.lambda_handler"
  runtime           = "python3.8"
  source_code_hash  = filebase64sha256("lambda_function.zip")
}

resource "aws_lambda_permission" "allow_s3_event" {
  provider        = aws.localstack
  statement_id    = "AllowExecutionFromS3Bucket"
  action          = "lambda:InvokeFunction"
  function_name   = aws_lambda_function.s3_copy_lambda.function_name
  principal       = "s3.amazonaws.com"
  source_arn      = aws_s3_bucket.s3_start.arn
}

resource "aws_s3_bucket_notification" "s3_start_notification" {
  provider = aws.localstack
  bucket   = aws_s3_bucket.s3_start.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_copy_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_sns_topic" "example_topic" {
  provider = aws.localstack
  name     = "example-topic"
}

resource "aws_sns_topic_subscription" "example_subscription" {
  provider  = aws.localstack
  topic_arn = aws_sns_topic.example_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.s3_copy_lambda.arn
}

resource "aws_s3_bucket_notification" "s3_start_notification_with_sns" {
  provider = aws.localstack
  bucket   = aws_s3_bucket.s3_start.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_copy_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  topic {
    topic_arn = aws_sns_topic.example_topic.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

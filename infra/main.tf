terraform {
  required_providers {
    aws = {
      version = ">= 4.0.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  access_key = "AKIAXYHY7IJVVWQJY6AT"
  secret_key = "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"
  region = "ca-central-1"
}

## Local variables for functions
locals {
  function_name = "get-obituaries-30139868"
  get_obituaries_handler_name = "main.get_lambda_handler_30139868"
  get_obituaries_artifact_name = "get-obituaries-artifact.zip"  

  function_name1 = "create-obituary-30139868"
  create_obituary_handler_name = "main.create_lambda_handler_30139868"
  create_obituary_artifact_name = "create-obituary-artifact.zip" 
}

#Create a role for the get-obituaries lambda function 
resource "aws_iam_role" "get_obituaries_lambda" {
  name = "iam-for-lambda-${local.function_name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

#Create a role for the create-obituary lambda function 
resource "aws_iam_role" "create_obituary_lambda" {
  name = "iam-for-lambda-${local.function_name1}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

#create archive file from main.py for get-obituaries
data "archive_file" "get_obituaries_lambda" {
  type = "zip"
  source_file = "../functions/get-obituaries/main.py"
  output_path = "get-obituaries-artifact.zip"
}

#create archive file from main.py for create-obituary
data "archive_file" "create_obituary_lambda" {
  type = "zip"
  source_dir = "../functions/create-obituary"
  output_path = "create-obituary-artifact.zip"
}

# create a Lambda function get-obituaries
resource "aws_lambda_function" "get_obituaries_lambda" {
  role          = aws_iam_role.get_obituaries_lambda.arn
  function_name = local.function_name
  handler       = local.get_obituaries_handler_name
  filename      = local.get_obituaries_artifact_name
  source_code_hash = data.archive_file.get_obituaries_lambda.output_base64sha256     
  runtime       = "python3.9"
  }

  # create a Lambda function create-obituary
resource "aws_lambda_function" "create_obituary_lambda" {
  role          = aws_iam_role.create_obituary_lambda.arn
  function_name = local.function_name1
  handler       = local.create_obituary_handler_name
  filename      = local.create_obituary_artifact_name
  source_code_hash = data.archive_file.create_obituary_lambda.output_base64sha256   
  runtime       = "python3.9"
  timeout       = 20
  }

# create a policy for publishing logs to CloudWatch for get-obituaries 
resource "aws_iam_policy" "logs_get" {
  name        = "lambda-logging-${local.function_name}"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "dynamodb:Query",
        "dynamodb:GetItem",
        "dynamodb:Scan",
        "ssm:GetParameter",
        "ssm:GetParametersByPath",
        "polly:SynthesizeSpeech"
      ],
      "Resource": ["arn:aws:logs:*:*:*", "${aws_dynamodb_table.obituary-30140219.arn}", "*", "*"],
      "Effect": "Allow"
    }
  ]
}
EOF
}

# create a policy for publishing logs to CloudWatch for create-obituary 
resource "aws_iam_policy" "logs_create" {
  name        = "lambda-logging-${local.function_name1}"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "dynamodb:PutItem",
        "ssm:GetParameter",
        "ssm:GetParametersByPath",
        "polly:SynthesizeSpeech"
      ],
      "Resource": ["arn:aws:logs:*:*:*", "${aws_dynamodb_table.obituary-30140219.arn}", "*", "*"],
      "Effect": "Allow"
    }
  ]
}
EOF
}

# attach the above policy to the function role
resource "aws_iam_role_policy_attachment" "lambda_logs_get" {
  role       = aws_iam_role.get_obituaries_lambda.name
  policy_arn = aws_iam_policy.logs_get.arn
}

# attach the above policy to the function role
resource "aws_iam_role_policy_attachment" "lambda_logs_create" {
  role       = aws_iam_role.create_obituary_lambda.name
  policy_arn = aws_iam_policy.logs_create.arn
}

# Create Lambda function URLs
resource "aws_lambda_function_url" "url_get" {
  function_name      = aws_lambda_function.get_obituaries_lambda.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["GET"]
    allow_headers     = ["*"]
    expose_headers    = ["keep-alive", "date"]
  }
}

# Create Lambda function URLs
resource "aws_lambda_function_url" "url_create" {
  function_name      = aws_lambda_function.create_obituary_lambda.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["POST"]
    allow_headers     = ["*"]
    expose_headers    = ["keep-alive", "date"]
  }
}

output "get_obituaries_lambda_url" {
  value = aws_lambda_function_url.url_get.function_url
}

output "create_obituary_lambda_url" {
  value = aws_lambda_function_url.url_create.function_url
}

# Creating DynamosDB table
resource "aws_dynamodb_table" "obituary-30140219" {
  name         = "obituary-30140219"
  billing_mode = "PROVISIONED"

  read_capacity = 1
  write_capacity = 1
  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }
}


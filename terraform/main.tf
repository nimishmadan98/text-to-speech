terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name               = "lambda-polly-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# IAM Policy for Polly Access
resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda-polly-policy"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["polly:SynthesizeSpeech"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../lambda/TextToSpeechLambda.py"
  output_path = "${path.module}/../lambda/TextToSpeechLambda.zip"
}

# Lambda Function
resource "aws_lambda_function" "text_to_speech" {
  function_name = "TextToSpeechLambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "TextToSpeechLambda.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30

  filename = "${path.module}/../lambda/TextToSpeechLambda.zip"

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.static_site.bucket
    }
  }
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "rest_api" {
  name = "TextToSpeechAPI"
  description = "REST API for text-to-speech Lambda integration"
}

# API Gateway Resource
resource "aws_api_gateway_resource" "synthesize_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "synthesize"
}

# API Gateway Method
resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.synthesize_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway Integration with Lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.synthesize_resource.id
  http_method = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.text_to_speech.invoke_arn
}

# CORS Preflight OPTIONS Method
resource "aws_api_gateway_method" "options_method" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.synthesize_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# CORS Method Response
resource "aws_api_gateway_method_response" "cors_method_response" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.synthesize_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# CORS Integration Response
resource "aws_api_gateway_integration_response" "cors_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.synthesize_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Integration for OPTIONS Method
resource "aws_api_gateway_integration" "cors_integration" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.synthesize_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "post_method_response" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.synthesize_resource.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.synthesize_resource.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}


# API Gateway Deployment
resource "aws_api_gateway_deployment" "rest_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  depends_on = [
        aws_api_gateway_method_response.post_method_response,
        aws_api_gateway_integration_response.post_integration_response,
        aws_api_gateway_integration.lambda_integration,
        aws_api_gateway_integration.cors_integration,
        aws_api_gateway_method_response.cors_method_response,
        aws_api_gateway_integration_response.cors_integration_response,
    ]

  stage_name = "prod"
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.text_to_speech.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*"
}

resource "aws_s3_bucket" "static_site" {
  bucket = var.bucket_name
}

# Website configuration for the S3 bucket
resource "aws_s3_bucket_website_configuration" "static_site_website" {
  bucket = aws_s3_bucket.static_site.id

  index_document {
    suffix = "index.html"
  }
}

# Generate dynamic index.html with API URL
data "template_file" "dynamic_index" {
  template = file("${path.module}/../static/index.html")

  vars = {
    API_ENDPOINT = aws_api_gateway_deployment.rest_api_deployment.invoke_url
  }
}

# Upload index.html to S3
resource "aws_s3_object" "index_html" {
  bucket        = aws_s3_bucket.static_site.id
  key           = "index.html"
  content       = data.template_file.dynamic_index.rendered
  content_type  = "text/html"
  #acl           = "public-read"
}

resource "aws_s3_bucket_policy" "static_site_policy" {
  bucket = aws_s3_bucket.static_site.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::${aws_s3_bucket.static_site.bucket}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "static_site_access_block" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}




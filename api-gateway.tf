data "aws_region" "current" {}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "minecraft_api" {
  name        = "minecraft-server-api"
  description = "API to control Minecraft server"
}

# API Key
resource "aws_api_gateway_api_key" "minecraft_key" {
  name = "minecraft-api-key"
}

# Usage plan with rate limiting
resource "aws_api_gateway_usage_plan" "minecraft_usage_plan" {
  name = "minecraft-usage-plan"

  throttle_settings {
    rate_limit  = 1   # 1 request per second
    burst_limit = 1   # No burst allowed
  }

  quota_settings {
    limit  = 1440   # 1440 requests per period
    period = "DAY"
  }

  api_stages {
    api_id = aws_api_gateway_rest_api.minecraft_api.id
    stage  = aws_api_gateway_stage.prod.stage_name
  }
}

# Associate API key with usage plan
resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.minecraft_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.minecraft_usage_plan.id
}

output "api_key" {
  value       = aws_api_gateway_api_key.minecraft_key.value
  description = "API Gateway API Key"
  sensitive   = true
}

# API Gateway resource (/start)
resource "aws_api_gateway_resource" "start" {
  rest_api_id = aws_api_gateway_rest_api.minecraft_api.id
  parent_id   = aws_api_gateway_rest_api.minecraft_api.root_resource_id
  path_part   = "start"
}

# API Gateway POST method
resource "aws_api_gateway_method" "start_post" {
  rest_api_id   = aws_api_gateway_rest_api.minecraft_api.id
  resource_id   = aws_api_gateway_resource.start.id
  http_method   = "POST"
  authorization = "NONE"
  api_key_required = true  # Add this line
}

# Enable CORS for OPTIONS method
resource "aws_api_gateway_method" "start_options" {
  rest_api_id   = aws_api_gateway_rest_api.minecraft_api.id
  resource_id   = aws_api_gateway_resource.start.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "start_options" {
  rest_api_id = aws_api_gateway_rest_api.minecraft_api.id
  resource_id = aws_api_gateway_resource.start.id
  http_method = aws_api_gateway_method.start_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "start_options" {
  rest_api_id = aws_api_gateway_rest_api.minecraft_api.id
  resource_id = aws_api_gateway_resource.start.id
  http_method = aws_api_gateway_method.start_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "start_options" {
  rest_api_id = aws_api_gateway_rest_api.minecraft_api.id
  resource_id = aws_api_gateway_resource.start.id
  http_method = aws_api_gateway_method.start_options.http_method
  status_code = aws_api_gateway_method_response.start_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,x-api-key'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Lambda integration for POST
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.minecraft_api.id
  resource_id             = aws_api_gateway_resource.start.id
  http_method             = aws_api_gateway_method.start_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.start_minecraft.invoke_arn
}

resource "aws_api_gateway_method_response" "start_post_200" {
  rest_api_id = aws_api_gateway_rest_api.minecraft_api.id
  resource_id = aws_api_gateway_resource.start.id
  http_method = aws_api_gateway_method.start_post.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_minecraft.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.minecraft_api.execution_arn}/*/*"
}

# Deploy API
resource "aws_api_gateway_deployment" "minecraft_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration.start_options
  ]

  rest_api_id = aws_api_gateway_rest_api.minecraft_api.id

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/minecraft-server-api"
  retention_in_days = 7
}

# IAM role for API Gateway to write to CloudWatch
resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "api-gateway-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  role       = aws_iam_role.api_gateway_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# API Gateway account settings (required once per region)
resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn

  depends_on = [
    aws_iam_role_policy_attachment.api_gateway_cloudwatch
  ]
}

# API Gateway Stage
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.minecraft_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.minecraft_api.id
  stage_name    = "prod"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      errorMessage   = "$context.error.message"
    })
  }

  depends_on = [aws_api_gateway_account.main]
}

# Method settings for throttling at stage level
resource "aws_api_gateway_method_settings" "prod_settings" {
  rest_api_id = aws_api_gateway_rest_api.minecraft_api.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "*/*"

  settings {
    throttling_rate_limit  = 1
    throttling_burst_limit = 1
  }
}

# Output the API URL
output "api_url" {
  value       = "https://${aws_api_gateway_rest_api.minecraft_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/start"
  description = "API Gateway endpoint URL"
}

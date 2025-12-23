# Lambda execution role
resource "aws_iam_role" "lambda_role" {
  name = "minecraft-server-start-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy to allow Lambda to start EC2 instances
resource "aws_iam_role_policy" "lambda_ec2_policy" {
  name = "minecraft-lambda-ec2-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy to read instance ID from Parameter Store
resource "aws_iam_role_policy" "lambda_ssm_read_policy" {
  name = "minecraft-lambda-ssm-read-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = "arn:aws:ssm:us-east-2:*:parameter/minecraft/instance_id"
      }
    ]
  })
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/start-minecraft-server"
  retention_in_days = 7
}

# Create zip file from Lambda source
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda function
resource "aws_lambda_function" "start_minecraft" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "start-minecraft-server"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      INSTANCE_ID_PARAM = "/minecraft/instance_id"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs,
    aws_iam_role_policy_attachment.lambda_basic
  ]
}

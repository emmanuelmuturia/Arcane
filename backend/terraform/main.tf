provider "aws" {
  region = var.region
  profile = var.profile
}

resource "aws_vpc" "arcane_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "arcane-vpc"
  }
}

resource "aws_subnet" "arcane_subnet" {
  vpc_id                  = aws_vpc.arcane_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "arcane_gw" {
  vpc_id = aws_vpc.arcane_vpc.id
}

resource "aws_route_table" "arcane_route_table" {
  vpc_id = aws_vpc.arcane_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.arcane_gw.id
  }
}

resource "aws_route_table_association" "arcane_route_assoc" {
  subnet_id      = aws_subnet.arcane_subnet.id
  route_table_id = aws_route_table.arcane_route_table.id
}

resource "aws_security_group" "arcane_sg" {
  name        = "arcane-sg"
  description = "Allow SSH and HTTP..."
  vpc_id      = aws_vpc.arcane_vpc.id

  ingress {
    description = "SSH..."
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP..."
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "arcane_ec2" {
  ami                         = "ami-0c02fb55956c7d316" # Amazon Linux 2 [us-east-1]...
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.arcane_subnet.id
  vpc_security_group_ids      = [aws_security_group.arcane_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = {
    Name = "arcane-instance"
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "arcane-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "lambda_basic_exec" {
  name       = "arcane-lambda-basic-exec"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "arcane_lambda" {
  function_name = "arcane-self-heal"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"

  filename         = "${path.module}/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_function.zip")

  depends_on = [aws_iam_policy_attachment.lambda_basic_exec]

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.arcane_alerts.arn
    }
  }
}

resource "aws_api_gateway_rest_api" "arcane_api" {
  name        = "arcane-api"
  description = "The Arcane REST API..."
}

resource "aws_api_gateway_resource" "arcane_resource" {
  rest_api_id = aws_api_gateway_rest_api.arcane_api.id
  parent_id   = aws_api_gateway_rest_api.arcane_api.root_resource_id
  path_part   = "heal"
}

resource "aws_api_gateway_method" "arcane_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.arcane_api.id
  resource_id   = aws_api_gateway_resource.arcane_resource.id
  http_method   = "POST"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "arcane_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.arcane_api.id
  resource_id = aws_api_gateway_resource.arcane_resource.id
  http_method = aws_api_gateway_method.arcane_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.arcane_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "arcane_deployment" {
  depends_on = [
    aws_api_gateway_integration.arcane_lambda_integration,
    aws_api_gateway_integration.arcane_get_lambda_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.arcane_api.id
  stage_name  = "prod"
}

resource "aws_lambda_permission" "allow_api_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.arcane_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.arcane_api.execution_arn}/*/*"
}


resource "aws_iam_policy" "ec2_reboot_policy" {
  name = "arcane-ec2-reboot-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RebootInstances"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = aws_sns_topic.arcane_alerts.arn
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "attach_ec2_reboot_policy" {
  name       = "arcane-attach-ec2-policy"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = aws_iam_policy.ec2_reboot_policy.arn
}

resource "aws_sns_topic" "arcane_alerts" {
  name = "arcane-self-heal-alerts"
}

resource "aws_sns_topic_subscription" "arcane_email_alert" {
  topic_arn = aws_sns_topic.arcane_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_log_group" "arcane_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.arcane_lambda.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_metric_alarm" "ec2_health_check" {
  alarm_name          = "arcane-ec2-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "Triggers if EC2 Status Check fails..."
  alarm_actions       = [aws_lambda_function.arcane_lambda.arn]
  dimensions = {
    InstanceId = aws_instance.arcane_ec2.id
  }
}

resource "aws_api_gateway_api_key" "arcane_api_key" {
  name        = "arcane-api-key"
  description = "API key for accessing Arcane API"
  enabled     = true
}

resource "aws_api_gateway_usage_plan" "arcane_usage_plan" {
  name = "arcane-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.arcane_api.id
    stage  = aws_api_gateway_deployment.arcane_deployment.stage_name
  }

  throttle_settings {
    rate_limit  = 10
    burst_limit = 2
  }

  quota_settings {
    limit  = 100
    period = "DAY"
  }
}

resource "aws_api_gateway_usage_plan_key" "arcane_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.arcane_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.arcane_usage_plan.id
}

resource "aws_lambda_function" "arcane_get_lambda" {
  function_name = "arcane-get-endpoint"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_get_function.lambda_handler"
  runtime       = "python3.12"

  filename         = "${path.module}/lambda_get_function.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_get_function.zip")

  depends_on = [aws_iam_policy_attachment.lambda_basic_exec]
}

resource "aws_api_gateway_resource" "arcane_get_resource" {
  rest_api_id = aws_api_gateway_rest_api.arcane_api.id
  parent_id   = aws_api_gateway_rest_api.arcane_api.root_resource_id
  path_part   = "status"
}

resource "aws_api_gateway_method" "arcane_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.arcane_api.id
  resource_id   = aws_api_gateway_resource.arcane_get_resource.id
  http_method   = "GET"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "arcane_get_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.arcane_api.id
  resource_id             = aws_api_gateway_resource.arcane_get_resource.id
  http_method             = aws_api_gateway_method.arcane_get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.arcane_get_lambda.invoke_arn
}

resource "aws_lambda_permission" "allow_api_invoke_get" {
  statement_id  = "AllowExecutionFromAPIGatewayGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.arcane_get_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.arcane_api.execution_arn}/*/*"
}

resource "aws_iam_role_policy" "lambda_ec2_metrics_policy" {
  name = "lambda-ec2-metrics-policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "cloudwatch:GetMetricStatistics"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}
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

  filename         = "${path.module}/backend/lambda/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/backend/lambda/lambda_function.zip")

  depends_on = [aws_iam_policy_attachment.lambda_basic_exec]
}

resource "aws_apigatewayv2_api" "arcane_api" {
  name          = "arcane-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "arcane_integration" {
  api_id             = aws_apigatewayv2_api.arcane_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.arcane_lambda.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "arcane_route" {
  api_id    = aws_apigatewayv2_api.arcane_api.id
  route_key = "POST /heal"
  target    = "integrations/${aws_apigatewayv2_integration.arcane_integration.id}"
}

resource "aws_apigatewayv2_stage" "arcane_stage" {
  api_id      = aws_apigatewayv2_api.arcane_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "allow_api_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.arcane_lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.arcane_api.execution_arn}/*/*"
}
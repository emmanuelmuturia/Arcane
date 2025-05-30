output "instance_public_ip" {
  description = "The public IP of the EC2 Instance..."
  value       = aws_instance.arcane_ec2.public_ip
}

output "instance_id" {
  description = "The ID of the EC2 Instance..."
  value       = aws_instance.arcane_ec2.id
}

output "api_gateway_url" {
  value = aws_api_gateway_rest_api.arcane_api.id
}

output "sns_topic_arn" {
  description = "The ARN of the SNS Topic..."
  value = aws_sns_topic.arcane_alerts.arn
}

output "lambda_function_name" {
  description = "The name of the Lambda Function..."
  value = aws_lambda_function.arcane_lambda.function_name
}
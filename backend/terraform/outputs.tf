output "instance_public_ip" {
  description = "The public IP of the EC2 Instance..."
  value       = aws_instance.arcane_ec2.public_ip
}

output "instance_id" {
  description = "The ID of the EC2 Instance..."
  value       = aws_instance.arcane_ec2.id
}

output "api_gateway_url" {
  description = "The full Invoke URL of the REST API..."
  value = "https://${aws_api_gateway_rest_api.arcane_api.id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_deployment.arcane_deployment.stage_name}/heal"
}

output "sns_topic_arn" {
  description = "The ARN of the SNS Topic..."
  value = aws_sns_topic.arcane_alerts.arn
}

output "lambda_function_name" {
  description = "The name of the Lambda Function..."
  value = aws_lambda_function.arcane_lambda.function_name
}
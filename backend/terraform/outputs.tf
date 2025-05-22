output "instance_public_ip" {
  description = "The public IP of the EC2 Instance..."
  value       = aws_instance.arcane_ec2.public_ip
}

output "instance_id" {
  description = "The ID of the EC2 Instance..."
  value       = aws_instance.arcane_ec2.id
}
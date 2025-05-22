variable "region" {
  description = "The AWS Region..."
  default     = "us-east-1"
}

variable "instance_type" {
  description = "The EC2 Instance Type..."
  default     = "t2.micro"
}

variable "key_name" {
  description = "The name of The SSH Key Pair..."
  default     = "arcane-key"
}
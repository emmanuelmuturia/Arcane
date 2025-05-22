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
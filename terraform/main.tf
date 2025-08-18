terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

variable "image" {
  description = "Docker image to deploy"
  type        = string
}

# Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Security group allowing HTTP access
resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Allow HTTP access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
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

# CloudWatch log group for Docker logs
resource "aws_cloudwatch_log_group" "docker_logs" {
  name              = "my-docker-logs1"
  retention_in_days = 7
}

# EC2 instance
resource "aws_instance" "app_server" {
  ami                    = "ami-01de4781572fa1285" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user

              # Pull and run Docker container
              docker pull ${var.image}
              docker run -d -p 80:5000 \
                --log-driver=awslogs \
                --log-opt awslogs-region=us-east-2 \
                --log-opt awslogs-group=my-docker-logs1 \
                --log-opt awslogs-stream=${var.image} \
                ${var.image}
              EOF

  tags = {
    Name = "TerraformAppServer"
  }
}

output "instance_public_ip" {
  value = aws_instance.app_server.public_ip
}

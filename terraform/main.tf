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

# Security group allowing HTTP access (unique name)
resource "aws_security_group" "app_sg" {
  name        = "app-sg-terraform-unique1"
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

# CloudWatch log group (unique name)
resource "aws_cloudwatch_log_group" "docker_logs" {
  name              = "my-docker-logs-terraform-unique"
  retention_in_days = 7
}

# IAM Role for EC2 (Session Manager + CloudWatch)
resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2-ssm-role-terraform-unique1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach Session Manager policy
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch policy
resource "aws_iam_role_policy_attachment" "cw_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance profile (unique name)
resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "ec2-ssm-profile-terraform-unique2"
  role = aws_iam_role.ec2_ssm_role.name
}

locals {
  safe_stream_name = replace(var.image, "/|:", "-")
}
# EC2 instance
resource "aws_instance" "app_server" {

  ami                    = "ami-01de4781572fa1285" # Amazon Linux 2
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name

  user_data = <<-EOF
#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
docker pull ${var.image}
docker run -d -p 80:5000 \
  --log-driver=awslogs \
  --log-opt awslogs-region=us-east-2 \
  --log-opt awslogs-group=my-docker-logs-terraform-unique \
  --log-opt awslogs-stream=${local.safe_stream_name} \
  ${var.image}
EOF

  tags = {
    Name = "TerraformAppServer"
  }
}

# Outputs
output "instance_public_ip" {
  value = aws_instance.app_server.public_ip
}

output "instance_id" {
  value = aws_instance.app_server.id
}

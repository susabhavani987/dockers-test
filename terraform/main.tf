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

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Security Group
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

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "docker_logs" {
  name              = "my-docker-logs-terraform-unique"
  retention_in_days = 7
}

# IAM Role for EC2 (SSM + CloudWatch)
resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2-ssm-role-terraform-unique4"

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

# Attach SSM Managed Policy
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch Agent Policy
resource "aws_iam_role_policy_attachment" "cw_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "ec2-ssm-profile-terraform-unique4"
  role = aws_iam_role.ec2_ssm_role.name
}

# EC2 Instance
resource "aws_instance" "app_server" {
  ami                    = "ami-01de4781572fa1285"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name

  user_data = <<-EOF
#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -aG docker ec2-user

# Start SSM agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Docker variables
IMAGE="${var.image}"
SAFE_STREAM_NAME=$(echo $IMAGE | sed 's/[:\/]/-/g')

# Stop/remove existing container if exists
if docker ps -a --format '{{.Names}}' | grep -Eq '^my-app-container$'; then
    docker stop my-app-container
    docker rm my-app-container
fi

# Pull and run Docker image
docker pull $IMAGE
docker run -d -p 80:5000 \
  --name my-app-container \
  --log-driver=awslogs \
  --log-opt awslogs-region=us-east-2 \
  --log-opt awslogs-group=my-docker-logs-terraform-unique \
  --log-opt awslogs-stream=$SAFE_STREAM_NAME \
  $IMAGE
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

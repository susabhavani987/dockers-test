provider "aws" {
  region = "us-east-2"  # or use a variable
}

variable "image" {
  description = "Docker image to deploy"
  type        = string
}

resource "aws_instance" "app_server" {
  ami           = "ami-01de4781572fa1285"  # Amazon Linux 2 AMI (update for your region)
  instance_type = "t2.micro"

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3 docker
              service docker start
              usermod -a -G docker ec2-user

              # Pull and run Docker container with the image passed
              docker pull ${var.image}
			  docker run -d \
               --log-driver=awslogs \
               --log-opt awslogs-region=us-east-2 \
               --log-opt awslogs-group=my-docker-logs \
               --log-opt awslogs-stream=${var.image} \
                ${var.image}

              # Alternatively, if you want to run app.py directly (if copied)
              # python3 /path/to/app.py
              EOF

  tags = {
    Name = "TerraformAppServer"
  }
}

output "instance_public_ip" {
  value = aws_instance.app_server.public_ip
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "image" {
  description = "Docker image to deploy (repository:tag)"
  type        = string
}

variable "service_desired_count" {
  type    = number
  default = 1
}

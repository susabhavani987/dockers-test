variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}



variable "service_desired_count" {
  type    = number
  default = 1
}

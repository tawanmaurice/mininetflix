variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name tag prefix"
  type        = string
  default     = "mini-netflix"
}

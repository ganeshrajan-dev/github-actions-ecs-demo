variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "ecs-demo"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 3000
}

variable "app_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}

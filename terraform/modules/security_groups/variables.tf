variable "deployment_platform" {
  type        = string
  description = "elastic_beanstalk | ecs_fargate_codedeploy — selects which tier security groups are created for DB access."

  validation {
    condition = contains([
      "elastic_beanstalk",
      "ecs_fargate_codedeploy",
    ], var.deployment_platform)
    error_message = "deployment_platform must be elastic_beanstalk or ecs_fargate_codedeploy."
  }
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR; used to allow the load balancer (in-VPC) to reach app instances."
}

variable "application_port" {
  type        = number
  description = "Container port (Gunicorn)."
  default     = 5000
}

variable "tags" {
  type    = map(string)
  default = {}
}

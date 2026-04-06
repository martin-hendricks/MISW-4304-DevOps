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

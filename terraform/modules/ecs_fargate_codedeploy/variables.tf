variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnets for the Application Load Balancer."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnets for Fargate tasks."
}

variable "ecs_tasks_security_group_id" {
  type        = string
  description = "Security group attached to Fargate tasks (ingress tightened by this module)."
}

variable "database_url" {
  type      = string
  sensitive = true
}

variable "jwt_secret_key" {
  type      = string
  sensitive = true
}

variable "jwt_expires_hours" {
  type    = string
  default = "24"
}

variable "service_username" {
  type = string
}

variable "service_password" {
  type      = string
  sensitive = true
}

variable "run_db_init" {
  type    = string
  default = "true"
}

variable "db_init_required" {
  type    = string
  default = "false"
}

variable "extra_environment_variables" {
  type        = map(string)
  description = "Extra non-sensitive container env vars."
  default     = {}
}

variable "container_port" {
  type    = number
  default = 5000
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "desired_count" {
  type        = number
  description = "Desired Fargate task count."
  default     = 2
}

variable "task_cpu" {
  type        = number
  description = "Task CPU units for Fargate (e.g. 256)."
  default     = 256
}

variable "task_memory" {
  type        = number
  description = "Task memory (MiB) for Fargate (e.g. 512)."
  default     = 512
}

variable "create_codedeploy_artifact_bucket" {
  type        = bool
  description = "Optional S3 bucket for deployment revisions (appspec/taskdef payloads)."
  default     = false
}

variable "alb_ingress_cidr_ipv4" {
  type        = string
  description = "Clients allowed to reach the ALB (HTTP / test listener)."
  default     = "0.0.0.0/0"
}

variable "tags" {
  type    = map(string)
  default = {}
}

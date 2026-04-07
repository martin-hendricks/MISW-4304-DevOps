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
  description = "Subnets for the load balancer (typically public)."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Subnets for EC2 instances (typically private + NAT)."
}

variable "instance_security_group_ids" {
  type        = list(string)
  description = "Security groups for EB instances."
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the Auto Scaling group."
  default     = "t3.small"
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 4
}

variable "application_port" {
  type        = number
  description = "Container / Gunicorn port."
  default     = 5000
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "deployment_policy" {
  type        = string
  description = "Elastic Beanstalk application deployment policy (same env; change via tfvars + apply)."
  default     = "Rolling"
}

variable "deployment_batch_size_type" {
  type        = string
  description = "BatchSizeType for rolling-style policies (Fixed or Percentage). Ignored effect for AllAtOnce in practice."
  default     = "Percentage"
}

variable "deployment_batch_size" {
  type        = string
  description = "Batch size string per EB (e.g. 50 for 50%%, or 1 for one instance)."
  default     = "50"
}

variable "solution_stack_regex" {
  type        = string
  description = "Regex to pick the newest Docker platform stack in the region."
  default     = "^64bit Amazon Linux 2023 v[0-9.]+ running Docker$"
}

variable "solution_stack_name" {
  type        = string
  description = "If non-empty, use this exact solution stack instead of the regex data source."
  default     = ""
}

variable "associate_public_ip" {
  type        = bool
  description = "Set true only if instances run in public subnets without NAT."
  default     = false
}

variable "database_url" {
  type        = string
  description = "SQLAlchemy DATABASE_URL (postgresql+psycopg://...)."
  sensitive   = true
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
  description = "Additional EB env vars; keep values non-secret (secrets use dedicated inputs above)."
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}

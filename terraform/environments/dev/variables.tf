variable "aws_region" {
  type        = string
  description = "AWS region for all resources."
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Short prefix for resource names."
  default     = "blacklist-svc"
}

variable "environment" {
  type        = string
  description = "Stage name (dev, staging, prod)."
  default     = "dev"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC IPv4 CIDR."
  default     = "10.0.0.0/16"
}

variable "single_nat_gateway" {
  type        = bool
  description = "One NAT for all private subnets (cheaper dev setup)."
  default     = true
}

variable "jwt_secret_key" {
  type        = string
  description = "Flask-JWT secret; use a long random value in real deployments."
  sensitive   = true
}

variable "service_username" {
  type        = string
  description = "Basic auth / service user for the API (see app config)."
  default     = "admin"
}

variable "service_password" {
  type        = string
  description = "Service user password."
  sensitive   = true
}

variable "jwt_expires_hours" {
  type    = string
  default = "24"
}

variable "run_db_init" {
  type        = string
  description = "Set to true to run scripts/init_db.py on container start."
  default     = "true"
}

variable "db_init_required" {
  type    = string
  default = "false"
}

variable "rds_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "rds_allocated_storage" {
  type    = number
  default = 20
}

variable "rds_max_allocated_storage" {
  type    = number
  default = 100
}

variable "rds_multi_az" {
  type    = bool
  default = false
}

variable "rds_backup_retention_period" {
  type        = number
  description = "RDS backup retention days. Use 0 for AWS Free Tier (7+ often fails with FreeTierRestrictionError). Paid accounts typically use 7-35."
  default     = 0
}

variable "rds_skip_final_snapshot" {
  type        = bool
  description = "Set false in production (requires final_snapshot_identifier when destroying)."
  default     = true
}

variable "rds_deletion_protection" {
  type    = bool
  default = false
}

variable "db_name" {
  type    = string
  default = "blacklist_db"
}

variable "db_username" {
  type    = string
  default = "appadmin"
}

variable "eb_instance_type" {
  type    = string
  default = "t3.small"
}

variable "eb_min_size" {
  type    = number
  default = 1
}

variable "eb_max_size" {
  type    = number
  default = 2
}

variable "solution_stack_name" {
  type        = string
  description = "Leave empty to auto-pick latest AL2023 Docker stack; set if the data source fails in your region."
  default     = ""
}

variable "solution_stack_regex" {
  type    = string
  default = "^64bit Amazon Linux 2023 v[0-9.]+ running Docker$"
}

variable "extra_tags" {
  type        = map(string)
  description = "Additional tags for taggable resources."
  default     = {}
}

variable "extra_eb_environment_variables" {
  type        = map(string)
  description = "Optional extra Elastic Beanstalk env vars (avoid secrets here; use dedicated variables)."
  default     = {}
}

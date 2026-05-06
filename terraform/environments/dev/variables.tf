variable "aws_region" {
  type        = string
  description = "AWS region for all resources."
  default     = "us-east-1"
}

variable "deployment_platform" {
  type        = string
  description = "elastic_beanstalk: EB + zip deploy (deploy_eb.sh). ecs_fargate_codedeploy: ECS Fargate + ALB Blue/Green + CodeDeploy + ECR."
  default     = "elastic_beanstalk"

  validation {
    condition = contains([
      "elastic_beanstalk",
      "ecs_fargate_codedeploy",
    ], var.deployment_platform)
    error_message = "deployment_platform must be elastic_beanstalk or ecs_fargate_codedeploy."
  }
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
  type        = number
  description = "Elastic Beanstalk Auto Scaling group minimum capacity."
  default     = 3
}

variable "eb_max_size" {
  type        = number
  description = "Elastic Beanstalk Auto Scaling group maximum capacity."
  default     = 6
}

variable "eb_deployment_policy" {
  type        = string
  description = "EB deployment policy: AllAtOnce, Rolling, RollingWithAdditionalBatch, or Immutable (same environment; change + apply to switch)."
  default     = "Rolling"

  validation {
    condition = contains([
      "AllAtOnce",
      "Rolling",
      "RollingWithAdditionalBatch",
      "Immutable",
    ], var.eb_deployment_policy)
    error_message = "eb_deployment_policy must be AllAtOnce, Rolling, RollingWithAdditionalBatch, or Immutable."
  }
}

variable "eb_deployment_batch_size_type" {
  type        = string
  description = "BatchSizeType for EB command namespace (Fixed or Percentage)."
  default     = "Percentage"

  validation {
    condition     = contains(["Fixed", "Percentage"], var.eb_deployment_batch_size_type)
    error_message = "eb_deployment_batch_size_type must be Fixed or Percentage."
  }
}

variable "eb_deployment_batch_size" {
  type        = string
  description = "Batch size as string (e.g. 33 for 33%%, 1 for one instance at a time)."
  default     = "33"
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

variable "ecs_desired_count" {
  type        = number
  description = "Fargate desired count (por task set estable). Durante CodeDeploy Blue/Green puedes ver el doble de tareas unos minutos."
  default     = 1
}

variable "ecs_task_cpu" {
  type        = number
  description = "Fargate task CPU units (256 = 0.25 vCPU)."
  default     = 256
}

variable "ecs_task_memory" {
  type        = number
  description = "Fargate task memory MiB."
  default     = 512
}

variable "ecs_create_codedeploy_artifact_bucket" {
  type        = bool
  description = "Create an S3 bucket for CodeDeploy revisions (appspec payloads). Optional."
  default     = false
}

variable "ecs_codedeploy_deployment_config_name" {
  type        = string
  description = "CodeDeploy predefined ECS config. Default shifts all traffic at once in blue/green."
  default     = "CodeDeployDefault.ECSAllAtOnce"
}

variable "ecs_fargate_cpu_architecture" {
  type        = string
  description = "Fargate task arch: X86_64 (amd64 image) or ARM64 (arm64 image). Must match docker push to ECR."
  default     = "X86_64"

  validation {
    condition     = contains(["X86_64", "ARM64"], var.ecs_fargate_cpu_architecture)
    error_message = "ecs_fargate_cpu_architecture must be X86_64 or ARM64."
  }
}

variable "extra_ecs_environment_variables" {
  type        = map(string)
  description = "Optional extra container env vars for ECS/Fargate (non-secret)."
  default     = {}
}

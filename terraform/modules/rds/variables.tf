variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnets for the DB subnet group."
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "Security groups for RDS (typically RDS SG only)."
}

variable "db_name" {
  type        = string
  description = "Initial database name."
  default     = "blacklist_db"
}

variable "db_username" {
  type        = string
  description = "Master username."
  default     = "appadmin"
}

variable "engine_version" {
  type        = string
  description = "PostgreSQL version (e.g. 16 or 16.4 — check RDS in your region)."
  default     = "16"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class."
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  type        = number
  description = "Allocated storage in GB."
  default     = 20
}

variable "max_allocated_storage" {
  type        = number
  description = "Autoscaling upper bound; set 0 to disable storage autoscaling."
  default     = 100
}

variable "multi_az" {
  type        = bool
  description = "Enable Multi-AZ."
  default     = false
}

variable "backup_retention_period" {
  type        = number
  description = "Backup retention days (0 disables automated backups)."
  default     = 7
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot on destroy (use true only in dev)."
  default     = true
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "publicly_accessible" {
  type        = bool
  description = "Must be false for private-only RDS."
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

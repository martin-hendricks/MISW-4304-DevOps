variable "project_name" {
  type        = string
  description = "Short name used in resource tags and names."
}

variable "environment" {
  type        = string
  description = "Deployment stage (e.g. dev, staging, prod)."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "AZ names to use (at least two for RDS and load-balanced EB)."
}

variable "single_nat_gateway" {
  type        = bool
  description = "If true, one NAT gateway shared by all private subnets (lower cost)."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Extra tags merged into all taggable resources."
  default     = {}
}

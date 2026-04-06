output "vpc_id" {
  value       = aws_vpc.this.id
  description = "VPC ID."
}

output "vpc_cidr_block" {
  value       = aws_vpc.this.cidr_block
  description = "VPC IPv4 CIDR (for security group rules)."
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "Public subnet IDs (ALB / NAT)."
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "Private subnet IDs (EB instances, RDS)."
}

output "availability_zones" {
  value       = var.availability_zones
  description = "AZs used by this network."
}

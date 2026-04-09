output "eb_instance_security_group_id" {
  value       = aws_security_group.eb_instances.id
  description = "Attach to Elastic Beanstalk EC2 instances."
}

output "rds_security_group_id" {
  value       = aws_security_group.rds.id
  description = "Attach to RDS."
}

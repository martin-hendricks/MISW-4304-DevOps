output "eb_instance_security_group_id" {
  value       = try(aws_security_group.eb_instances[0].id, null)
  description = "Attach to Elastic Beanstalk EC2 instances (null when deployment_platform is ecs_fargate_codedeploy)."
}

output "ecs_tasks_security_group_id" {
  value       = try(aws_security_group.ecs_tasks[0].id, null)
  description = "Attach to ECS Fargate tasks (null when deployment_platform is elastic_beanstalk)."
}

output "rds_security_group_id" {
  value       = aws_security_group.rds.id
  description = "Attach to RDS."
}

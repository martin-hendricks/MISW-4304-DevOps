output "ecr_repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "ECR URI base (without tag). Push images here before the first ECS deploy."
}

output "ecr_repository_name" {
  value = aws_ecr_repository.app.name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.this.arn
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "ecs_task_definition_arn" {
  value       = aws_ecs_task_definition.app.arn
  description = "Initial task definition; CodeDeploy rotates revisions after deployments."
}

output "ecs_task_definition_family" {
  value       = aws_ecs_task_definition.app.family
  description = "Task definition family (for register-task-definition from latest revision)."
}

output "codedeploy_application_name" {
  value = aws_codedeploy_app.ecs.name
}

output "codedeploy_deployment_group_name" {
  value = aws_codedeploy_deployment_group.ecs.deployment_group_name
}

output "alb_dns_name" {
  value       = aws_lb.public.dns_name
  description = "Public HTTP endpoint (listener 80 = production Blue/Green). Port 8080 = test/Green routing per CodeDeploy."
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "alb_target_group_blue_name" {
  value = aws_lb_target_group.blue.name
}

output "alb_target_group_green_name" {
  value = aws_lb_target_group.green.name
}

output "codedeploy_artifact_bucket_id" {
  value       = try(aws_s3_bucket.codedeploy_artifacts[0].id, null)
  description = "Present when create_codedeploy_artifact_bucket is true."
}

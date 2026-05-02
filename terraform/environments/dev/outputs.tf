output "deployment_platform" {
  value       = var.deployment_platform
  description = "Active compute/deploy path."
}

output "eb_cname" {
  value       = length(module.elastic_beanstalk) > 0 ? module.elastic_beanstalk[0].cname : null
  description = "Beanstalk hostname when deployment_platform is elastic_beanstalk."
}

output "eb_application_name" {
  value       = length(module.elastic_beanstalk) > 0 ? module.elastic_beanstalk[0].application_name : null
  description = "Beanstalk application name when deployment_platform is elastic_beanstalk."
}

output "eb_environment_name" {
  value       = length(module.elastic_beanstalk) > 0 ? module.elastic_beanstalk[0].environment_name : null
  description = "Beanstalk environment name when deployment_platform is elastic_beanstalk."
}

output "ecs_public_url" {
  value       = length(module.ecs_fargate_codedeploy) > 0 ? "http://${module.ecs_fargate_codedeploy[0].alb_dns_name}" : null
  description = "ALB DNS with HTTP scheme when deployment_platform is ecs_fargate_codedeploy (listener 80 = prod)."
}

output "ecs_alb_dns_name" {
  value       = length(module.ecs_fargate_codedeploy) > 0 ? module.ecs_fargate_codedeploy[0].alb_dns_name : null
  description = "ALB DNS when using ECS Blueprint (test traffic often on port 8080)."
}

output "ecs_ecr_repository_url" {
  value       = length(module.ecs_fargate_codedeploy) > 0 ? module.ecs_fargate_codedeploy[0].ecr_repository_url : null
  description = "Push container images here for ECS deployments."
}

output "ecs_task_definition_family" {
  value = length(module.ecs_fargate_codedeploy) > 0 ? module.ecs_fargate_codedeploy[0].ecs_task_definition_family : null
}

output "ecs_cluster_name" {
  value = length(module.ecs_fargate_codedeploy) > 0 ? module.ecs_fargate_codedeploy[0].ecs_cluster_name : null
}

output "ecs_service_name" {
  value = length(module.ecs_fargate_codedeploy) > 0 ? module.ecs_fargate_codedeploy[0].ecs_service_name : null
}

output "ecs_codedeploy_application_name" {
  value = length(module.ecs_fargate_codedeploy) > 0 ? module.ecs_fargate_codedeploy[0].codedeploy_application_name : null
}

output "ecs_codedeploy_deployment_group_name" {
  value = length(module.ecs_fargate_codedeploy) > 0 ? module.ecs_fargate_codedeploy[0].codedeploy_deployment_group_name : null
}

output "ecs_codedeploy_artifact_bucket_id" {
  value       = length(module.ecs_fargate_codedeploy) > 0 ? module.ecs_fargate_codedeploy[0].codedeploy_artifact_bucket_id : null
  description = "S3 bucket for deployment artifacts when ecs_create_codedeploy_artifact_bucket is true."
}

output "ecs_task_execution_role_arn" {
  value       = length(module.ecs_fargate_codedeploy) > 0 ? module.ecs_fargate_codedeploy[0].ecs_task_execution_role_arn : null
  description = "CodeBuild/CodePipeline: set ECS_EXECUTION_ROLE_ARN."
}

output "ecs_task_role_arn" {
  value       = length(module.ecs_fargate_codedeploy) > 0 ? module.ecs_fargate_codedeploy[0].ecs_task_role_arn : null
  description = "CodeBuild/CodePipeline: set ECS_TASK_ROLE_ARN."
}

output "ecs_cloudwatch_log_group_name" {
  value       = length(module.ecs_fargate_codedeploy) > 0 ? module.ecs_fargate_codedeploy[0].ecs_cloudwatch_log_group_name : null
  description = "CodeBuild/CodePipeline: set ECS_AWSLOGS_GROUP."
}

output "rds_endpoint" {
  value       = module.rds.endpoint
  description = "RDS hostname (credentials are sensitive; see Terraform state)."
}

output "vpc_id" {
  value = module.network.vpc_id
}

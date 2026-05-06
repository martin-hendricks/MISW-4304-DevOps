output "codebuild_projects" {
  value = {
    pipeline_build = aws_codebuild_project.devops_pipeline.name
    github_only    = aws_codebuild_project.github_standalone.name
  }
}

output "codepipeline_names" {
  value = [
    aws_codepipeline.devops_with_deploy.name,
    aws_codepipeline.beanstalk_build_only.name,
  ]
}

output "iam_roles_referenced_note" {
  value = <<-EOT
    Los roles codebuild-DevOps-service-role, devops-rol y
    AWSCodePipelineServiceRole-us-east-1-pipeline-beanstalk-devops solo se consultan con data.aws_iam_role.
    Terraform no gestiona políticas IAM aquí (siguen definidas solo en IAM en la cuenta).
    Si pipeline_deploy_target es ecs_codedeploy, el rol devops-rol debe poder invocar CodeDeploy y registrar
    despliegues ECS (añade políticas desde el asistente de CodePipeline para ECS Blue/Green o equivalente manual).
    El rol de CodeBuild necesita push a ECR (como el tutorial: permisos de capa/imagen sobre el repo).
  EOT
}

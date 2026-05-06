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
  EOT
}

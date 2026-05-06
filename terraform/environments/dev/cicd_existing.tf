# CodeBuild + CodePipeline ya creados en la cuenta (detectados vía AWS CLI).
# manage_existing_ci_resources = true: tras los imports, Terraform adopta recurso pero NO los roles IAM:
# el módulo usa data.aws_iam_role(...) — las políticas adjuntas e inline siguen solo en IAM (sin drift en Terraform).
#
# Defaults = escaneo cuenta ejemplo; sobrescribe en tfvars (repo fork, ARN CodeConnections).

module "existing_ci_cd" {
  count  = var.manage_existing_ci_resources ? 1 : 0
  source = "../../modules/existing_ci_cd"

  aws_region                                 = var.aws_region
  artifact_bucket_name                       = var.cicd_existing_artifact_bucket
  github_full_repository_id                  = var.cicd_existing_github_full_repository_id
  github_source_location_https               = var.cicd_existing_github_https_url
  source_branch_name                         = var.cicd_existing_source_branch
  codestar_connection_arn_pipeline_devops    = var.cicd_existing_codestar_arn_devops_pipeline
  codestar_connection_arn_pipeline_beanstalk = var.cicd_existing_codestar_arn_beanstalk_pipeline
  codebuild_environment_image_repo_name      = var.cicd_existing_image_repo_name
  elastic_beanstalk_application_name         = var.cicd_existing_eb_application_name
  elastic_beanstalk_environment_name         = var.cicd_existing_eb_environment_name
  tags                                       = local.extra_tags
}

# Replicar adopción en otro backend de state:
# terraform import 'module.existing_ci_cd[0].aws_codebuild_project.devops_pipeline' devops-project
# terraform import 'module.existing_ci_cd[0].aws_codebuild_project.github_standalone' DevOps
# terraform import 'module.existing_ci_cd[0].aws_codepipeline.devops_with_deploy' devops-pipeline
# terraform import 'module.existing_ci_cd[0].aws_codepipeline.beanstalk_build_only' pipeline-beanstalk-devops
# terraform apply -target=module.existing_ci_cd (evita otros cambios pendientes, p. ej. ALB)

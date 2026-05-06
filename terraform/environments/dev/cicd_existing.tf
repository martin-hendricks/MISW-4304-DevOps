# CodeBuild + CodePipeline ya creados en la cuenta (detectados vía AWS CLI).
# manage_existing_ci_resources = true: tras los imports, Terraform adopta recurso pero NO los roles IAM:
# el módulo usa data.aws_iam_role(...) — las políticas adjuntas e inline siguen solo en IAM (sin drift en Terraform).
#
# Defaults = escaneo cuenta ejemplo; sobrescribe en tfvars (repo fork, ARN CodeConnections).
#
# Si deployment_platform = ecs_fargate_codedeploy: devops-pipeline usa etapa Deploy → CodeDeployToECS (blue/green);
# CodeBuild project devops-project usa buildspec.pipeline.yml y nombres/ARN desde module.ecs_fargate_codedeploy.*.

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
  codebuild_environment_image_repo_name      = local.use_ecs_fargate_codedeploy ? module.ecs_fargate_codedeploy[0].ecr_repository_name : var.cicd_existing_image_repo_name

  pipeline_deploy_target           = local.use_ecs_fargate_codedeploy ? "ecs_codedeploy" : "elastic_beanstalk"
  codedeploy_application_name      = local.use_ecs_fargate_codedeploy ? module.ecs_fargate_codedeploy[0].codedeploy_application_name : ""
  codedeploy_deployment_group_name = local.use_ecs_fargate_codedeploy ? module.ecs_fargate_codedeploy[0].codedeploy_deployment_group_name : ""
  ecs_codebuild_execution_role_arn = local.use_ecs_fargate_codedeploy ? module.ecs_fargate_codedeploy[0].ecs_task_execution_role_arn : ""
  ecs_codebuild_task_role_arn      = local.use_ecs_fargate_codedeploy ? module.ecs_fargate_codedeploy[0].ecs_task_role_arn : ""
  ecs_codebuild_task_family        = local.use_ecs_fargate_codedeploy ? module.ecs_fargate_codedeploy[0].ecs_task_definition_family : ""
  ecs_codebuild_awslogs_group      = local.use_ecs_fargate_codedeploy ? module.ecs_fargate_codedeploy[0].ecs_cloudwatch_log_group_name : ""
  ecs_docker_platform              = local.use_ecs_fargate_codedeploy ? (var.ecs_fargate_cpu_architecture == "ARM64" ? "linux/arm64" : "linux/amd64") : ""

  elastic_beanstalk_application_name = var.cicd_existing_eb_application_name
  elastic_beanstalk_environment_name = var.cicd_existing_eb_environment_name
  tags                               = local.extra_tags
}

# Replicar adopción en otro backend de state:
# terraform import 'module.existing_ci_cd[0].aws_codebuild_project.devops_pipeline' devops-project
# terraform import 'module.existing_ci_cd[0].aws_codebuild_project.github_standalone' DevOps
# terraform import 'module.existing_ci_cd[0].aws_codepipeline.devops_with_deploy' devops-pipeline
# terraform import 'module.existing_ci_cd[0].aws_codepipeline.beanstalk_build_only' pipeline-beanstalk-devops
# terraform apply -target=module.existing_ci_cd (evita otros cambios pendientes, p. ej. ALB)

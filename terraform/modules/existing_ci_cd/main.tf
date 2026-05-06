data "aws_caller_identity" "current" {}

locals {
  account_id           = data.aws_caller_identity.current.account_id
  ecs_codedeploy_build = var.pipeline_deploy_target == "ecs_codedeploy"

  ecs_codebuild_task_env = local.ecs_codedeploy_build ? {
    TASKENV_DATABASE_URL      = var.ecs_pipeline_database_url
    TASKENV_JWT_SECRET_KEY    = var.ecs_pipeline_jwt_secret_key
    TASKENV_JWT_EXPIRES_HOURS = var.ecs_pipeline_jwt_expires_hours
    TASKENV_SERVICE_USERNAME  = var.ecs_pipeline_service_username
    TASKENV_SERVICE_PASSWORD  = var.ecs_pipeline_service_password
    TASKENV_RUN_DB_INIT       = var.ecs_pipeline_run_db_init
    TASKENV_DB_INIT_REQUIRED  = var.ecs_pipeline_db_init_required
  } : {}
}

data "aws_iam_role" "codebuild" {
  name = var.codebuild_service_role_name
}

data "aws_iam_role" "codepipeline_devops" {
  name = var.codepipeline_role_name_devops
}

data "aws_iam_role" "codepipeline_beanstalk" {
  name = var.codepipeline_role_name_beanstalk
}

data "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = var.artifact_bucket_name
}

resource "aws_codebuild_project" "devops_pipeline" {
  name           = "devops-project"
  service_role   = data.aws_iam_role.codebuild.arn
  build_timeout  = 60
  queued_timeout = 480

  artifacts {
    type      = "CODEPIPELINE"
    name      = "devops-project"
    packaging = "NONE"
  }

  source {
    type         = "CODEPIPELINE"
    buildspec    = local.ecs_codedeploy_build ? "buildspec.pipeline.yml" : "buildspec.yml"
    insecure_ssl = false
  }

  cache {
    type = "NO_CACHE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/amazonlinux-x86_64-standard:6.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    # Escaneo tenía false; buildspec.yml usa docker build → true o el build falla en CodeBuild.
    privileged_mode = true

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.account_id
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = var.codebuild_environment_image_repo_name
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
      type  = "PLAINTEXT"
    }

    dynamic "environment_variable" {
      for_each = local.ecs_codedeploy_build ? merge(
        { for k, v in {
          ECS_EXECUTION_ROLE_ARN = var.ecs_codebuild_execution_role_arn
          ECS_TASK_ROLE_ARN      = var.ecs_codebuild_task_role_arn
          ECS_TASK_FAMILY        = var.ecs_codebuild_task_family
          ECS_AWSLOGS_GROUP      = var.ecs_codebuild_awslogs_group
          DOCKER_PLATFORM        = trimspace(var.ecs_docker_platform)
        } : k => v if v != "" },
        local.ecs_codebuild_task_env,
      ) : {}

      content {
        name  = environment_variable.key
        value = environment_variable.value
        type  = "PLAINTEXT"
      }
    }
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
    s3_logs {
      status = "DISABLED"
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [encryption_key]

    precondition {
      condition = !local.ecs_codedeploy_build || (
        var.codedeploy_application_name != "" &&
        var.codedeploy_deployment_group_name != "" &&
        var.ecs_codebuild_execution_role_arn != "" &&
        var.ecs_codebuild_task_role_arn != "" &&
        var.ecs_codebuild_task_family != "" &&
        var.ecs_codebuild_awslogs_group != "" &&
        var.ecs_pipeline_database_url != "" &&
        var.ecs_pipeline_jwt_secret_key != "" &&
        var.ecs_pipeline_service_password != ""
      )
      error_message = "Con pipeline_deploy_target = ecs_codedeploy, rellena codedeploy_*, ecs_codebuild_* y ecs_pipeline_* (DB URL, JWT, password servicio) para el taskdef del pipeline."
    }
  }
}

resource "aws_codebuild_project" "github_standalone" {
  name           = "DevOps"
  service_role   = data.aws_iam_role.codebuild.arn
  build_timeout  = 60
  queued_timeout = 60

  artifacts {
    type = "NO_ARTIFACTS"
  }

  source {
    type                = "GITHUB"
    location            = var.github_source_location_https
    git_clone_depth     = 1
    insecure_ssl        = false
    report_build_status = false
    buildspec           = ""

    git_submodules_config {
      fetch_submodules = false
    }
  }

  cache {
    type = "NO_CACHE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux-x86_64-standard:6.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.account_id
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = var.codebuild_environment_image_repo_name
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
      type  = "PLAINTEXT"
    }
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
    s3_logs {
      status = "DISABLED"
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [encryption_key]
  }
}

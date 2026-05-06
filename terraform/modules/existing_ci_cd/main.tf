locals {
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}

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
    buildspec    = "buildspec.yml"
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
    privileged_mode             = true

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

resource "aws_codepipeline" "devops_with_deploy" {
  name           = "devops-pipeline"
  role_arn       = data.aws_iam_role.codepipeline_devops.arn
  pipeline_type  = "V2"
  execution_mode = "QUEUED"

  artifact_store {
    type     = "S3"
    location = data.aws_s3_bucket.codepipeline_artifacts.id
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      input_artifacts  = []
      output_artifacts = ["SourceArtifact"]
      namespace        = "SourceVariables"
      region           = var.aws_region
      run_order        = 1

      configuration = {
        BranchName           = var.source_branch_name
        ConnectionArn        = var.codestar_connection_arn_pipeline_devops
        DetectChanges        = "true"
        FullRepositoryId     = var.github_full_repository_id
        OutputArtifactFormat = "CODE_ZIP"
      }
    }

    on_failure {
      result = "RETRY"
      retry_configuration {
        retry_mode = "ALL_ACTIONS"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      namespace        = "BuildVariables"
      region           = var.aws_region
      run_order        = 1

      configuration = {
        ProjectName  = aws_codebuild_project.devops_pipeline.name
        BatchEnabled = "false"
      }
    }

    on_failure {
      result = "RETRY"
      retry_configuration {
        retry_mode = "ALL_ACTIONS"
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name             = "Deploy"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "ElasticBeanstalk"
      version          = "1"
      input_artifacts  = ["BuildArtifact"]
      output_artifacts = []
      namespace        = "DeployVariables"
      region           = var.aws_region
      run_order        = 1

      configuration = {
        ApplicationName = var.elastic_beanstalk_application_name
        EnvironmentName = var.elastic_beanstalk_environment_name
      }
    }

    on_failure {
      result = "ROLLBACK"
    }
  }

  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "Source"
      push {
        branches {
          includes = [var.source_branch_name]
        }
      }
    }
  }
}

resource "aws_codepipeline" "beanstalk_build_only" {
  name           = "pipeline-beanstalk-devops"
  role_arn       = data.aws_iam_role.codepipeline_beanstalk.arn
  pipeline_type  = "V2"
  execution_mode = "QUEUED"

  artifact_store {
    type     = "S3"
    location = data.aws_s3_bucket.codepipeline_artifacts.id
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      input_artifacts  = []
      output_artifacts = ["SourceArtifact"]
      namespace        = "SourceVariables"
      region           = var.aws_region
      run_order        = 1

      configuration = {
        BranchName           = var.source_branch_name
        ConnectionArn        = var.codestar_connection_arn_pipeline_beanstalk
        DetectChanges        = "true"
        FullRepositoryId     = var.github_full_repository_id
        OutputArtifactFormat = "CODE_ZIP"
      }
    }

    on_failure {
      result = "RETRY"
      retry_configuration {
        retry_mode = "ALL_ACTIONS"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      namespace        = "BuildVariables"
      region           = var.aws_region
      run_order        = 1

      configuration = {
        ProjectName = aws_codebuild_project.devops_pipeline.name
      }
    }

    on_failure {
      result = "RETRY"
      retry_configuration {
        retry_mode = "ALL_ACTIONS"
      }
    }
  }

  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "Source"
      push {
        branches {
          includes = [var.source_branch_name]
        }
      }
    }
  }
}

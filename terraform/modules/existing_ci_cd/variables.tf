variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "artifact_bucket_name" {
  type        = string
  description = "S3 bucket ya usado por CodePipeline (artefactos)."
}

variable "codebuild_service_role_name" {
  type    = string
  default = "codebuild-DevOps-service-role"
}

variable "codepipeline_role_name_devops" {
  type    = string
  default = "devops-rol"
}

variable "codepipeline_role_name_beanstalk" {
  type    = string
  default = "AWSCodePipelineServiceRole-us-east-1-pipeline-beanstalk-devops"
}

variable "github_full_repository_id" {
  type        = string
  description = "owner/repo para CodeStar connection (valor escaneado en la cuenta)."
}

variable "source_branch_name" {
  type    = string
  default = "main"
}

variable "codestar_connection_arn_pipeline_devops" {
  type        = string
  description = "Connection ARN usado por el pipeline devops-pipeline."
}

variable "codestar_connection_arn_pipeline_beanstalk" {
  type        = string
  description = "Connection ARN usado por pipeline-beanstalk-devops."
}

variable "github_source_location_https" {
  type        = string
  description = "HTTPS URL repo para el proyecto CodeBuild tipo GITHUB."
}

variable "codebuild_environment_image_repo_name" {
  type        = string
  description = "Valor escaneado IMAGE_REPO_NAME."
  default     = "blacklist_app"
}

variable "elastic_beanstalk_application_name" {
  type        = string
  description = "Nombre app EB para acción Deploy (devops-pipeline)."
  default     = "blacklist-svc-dev-app"
}

variable "elastic_beanstalk_environment_name" {
  type        = string
  description = "Nombre env EB para acción Deploy."
  default     = "blacklist-svc-dev-env"
}

variable "pipeline_deploy_target" {
  type        = string
  description = "elastic_beanstalk: etapa Deploy → Elastic Beanstalk. ecs_codedeploy: Deploy → CodeDeploy ECS blue/green (artefacto taskdef.json + appspec.json desde CodeBuild)."
  default     = "elastic_beanstalk"

  validation {
    condition     = contains(["elastic_beanstalk", "ecs_codedeploy"], var.pipeline_deploy_target)
    error_message = "pipeline_deploy_target must be elastic_beanstalk or ecs_codedeploy."
  }
}

variable "codedeploy_application_name" {
  type        = string
  description = "Nombre de la aplicación CodeDeploy (compute ECS). Obligatorio si pipeline_deploy_target = ecs_codedeploy."
  default     = ""
}

variable "codedeploy_deployment_group_name" {
  type        = string
  description = "Grupo de despliegue CodeDeploy. Obligatorio si pipeline_deploy_target = ecs_codedeploy."
  default     = ""
}

variable "ecs_codebuild_execution_role_arn" {
  type        = string
  description = "ARN rol ejecución task ECS; buildspec.pipeline.yml → taskdef."
  default     = ""
}

variable "ecs_codebuild_task_role_arn" {
  type        = string
  description = "ARN rol de tarea ECS."
  default     = ""
}

variable "ecs_codebuild_task_family" {
  type        = string
  description = "family de la task definition ECS (ej. blacklist-svc-dev-task)."
  default     = ""
}

variable "ecs_codebuild_awslogs_group" {
  type        = string
  description = "Nombre del log group CloudWatch (/ecs/.../app)."
  default     = ""
}

variable "ecs_docker_platform" {
  type        = string
  description = "Si no vacío, docker build --platform (ej. linux/amd64). Alinear con ecs_fargate_cpu_architecture."
  default     = ""
}

variable "ecs_pipeline_database_url" {
  type        = string
  description = "Misma DATABASE_URL que la task Terraform (postgresql+psycopg://...). Inyectada en taskdef vía CodeBuild."
  default     = ""
  sensitive   = true
}

variable "ecs_pipeline_jwt_secret_key" {
  type        = string
  description = "JWT secret para contenedor ECS desplegado por pipeline."
  default     = ""
  sensitive   = true
}

variable "ecs_pipeline_jwt_expires_hours" {
  type    = string
  default = "24"
}

variable "ecs_pipeline_service_username" {
  type    = string
  default = "admin"
}

variable "ecs_pipeline_service_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "ecs_pipeline_run_db_init" {
  type    = string
  default = "true"
}

variable "ecs_pipeline_db_init_required" {
  type    = string
  default = "false"
}

variable "tags" {
  type        = map(string)
  description = "Tags en proyectos CodeBuild (CodePipeline tiene API limitada)."
  default     = {}
}

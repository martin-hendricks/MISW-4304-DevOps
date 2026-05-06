data "aws_availability_zones" "available" {
  state = "available"
}

check "at_least_two_availability_zones" {
  assert {
    condition     = length(data.aws_availability_zones.available.names) >= 2
    error_message = "This configuration requires at least two enabled availability zones in the chosen region."
  }
}

locals {
  # ALB and RDS subnet groups need at least two AZs in most setups.
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  extra_tags = var.extra_tags

  use_elastic_beanstalk      = var.deployment_platform == "elastic_beanstalk"
  use_ecs_fargate_codedeploy = var.deployment_platform == "ecs_fargate_codedeploy"
}

module "network" {
  source = "../../modules/network"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = local.azs
  single_nat_gateway = var.single_nat_gateway
  tags               = local.extra_tags
}

module "security_groups" {
  source = "../../modules/security_groups"

  deployment_platform = var.deployment_platform
  project_name        = var.project_name
  environment         = var.environment
  vpc_id              = module.network.vpc_id
  vpc_cidr            = module.network.vpc_cidr_block
  application_port    = 5000
  tags                = local.extra_tags
}

module "rds" {
  source = "../../modules/rds"

  project_name            = var.project_name
  environment             = var.environment
  private_subnet_ids      = module.network.private_subnet_ids
  vpc_security_group_ids  = [module.security_groups.rds_security_group_id]
  db_name                 = var.db_name
  db_username             = var.db_username
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  max_allocated_storage   = var.rds_max_allocated_storage
  multi_az                = var.rds_multi_az
  backup_retention_period = var.rds_backup_retention_period
  skip_final_snapshot     = var.rds_skip_final_snapshot
  deletion_protection     = var.rds_deletion_protection
  tags                    = local.extra_tags
}

module "elastic_beanstalk" {
  count = local.use_elastic_beanstalk ? 1 : 0

  source = "../../modules/elastic_beanstalk"

  project_name                = var.project_name
  environment                 = var.environment
  vpc_id                      = module.network.vpc_id
  public_subnet_ids           = module.network.public_subnet_ids
  private_subnet_ids          = module.network.private_subnet_ids
  instance_security_group_ids = [module.security_groups.eb_instance_security_group_id]
  instance_type               = var.eb_instance_type
  min_size                    = var.eb_min_size
  max_size                    = var.eb_max_size
  deployment_policy           = var.eb_deployment_policy
  deployment_batch_size_type  = var.eb_deployment_batch_size_type
  deployment_batch_size       = var.eb_deployment_batch_size
  application_port            = 5000
  health_check_path           = "/health"
  solution_stack_name         = var.solution_stack_name
  solution_stack_regex        = var.solution_stack_regex
  associate_public_ip         = false

  database_url      = module.rds.database_url
  jwt_secret_key    = var.jwt_secret_key
  jwt_expires_hours = var.jwt_expires_hours
  service_username  = var.service_username
  service_password  = var.service_password
  run_db_init       = var.run_db_init
  db_init_required  = var.db_init_required

  extra_environment_variables = var.extra_eb_environment_variables
  tags                        = local.extra_tags

  depends_on = [module.rds]
}

module "ecs_fargate_codedeploy" {
  count = local.use_ecs_fargate_codedeploy ? 1 : 0

  source = "../../modules/ecs_fargate_codedeploy"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  ecs_tasks_security_group_id = module.security_groups.ecs_tasks_security_group_id
  database_url                = module.rds.database_url
  jwt_secret_key              = var.jwt_secret_key
  jwt_expires_hours           = var.jwt_expires_hours
  service_username            = var.service_username
  service_password            = var.service_password
  run_db_init                 = var.run_db_init
  db_init_required            = var.db_init_required

  container_port                    = 5000
  health_check_path                 = "/health"
  desired_count                     = var.ecs_desired_count
  task_cpu                          = var.ecs_task_cpu
  task_memory                       = var.ecs_task_memory
  extra_environment_variables       = var.extra_ecs_environment_variables
  create_codedeploy_artifact_bucket = var.ecs_create_codedeploy_artifact_bucket
  codedeploy_deployment_config_name = var.ecs_codedeploy_deployment_config_name
  fargate_cpu_architecture          = var.ecs_fargate_cpu_architecture
  tags                              = local.extra_tags

  depends_on = [module.rds]
}

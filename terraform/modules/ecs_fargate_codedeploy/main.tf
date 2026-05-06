locals {
  prefix = "${var.project_name}-${var.environment}"

  container_name = "app"

  env_static = merge(
    {
      DATABASE_URL      = var.database_url
      JWT_SECRET_KEY    = var.jwt_secret_key
      JWT_EXPIRES_HOURS = var.jwt_expires_hours
      SERVICE_USERNAME  = var.service_username
      SERVICE_PASSWORD  = var.service_password
      RUN_DB_INIT       = var.run_db_init
      DB_INIT_REQUIRED  = var.db_init_required
    },
    var.extra_environment_variables,
  )

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

resource "aws_ecr_repository" "app" {
  name                 = "${local.prefix}-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

resource "aws_ecs_cluster" "this" {
  name = "${local.prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.prefix}/app"
  retention_in_days = 7

  tags = local.common_tags
}

resource "aws_iam_role" "ecs_task_execution" {
  name_prefix = "${local.prefix}-ecs-exec-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_managed" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name_prefix = "${local.prefix}-ecs-task-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_security_group" "alb" {
  name        = "${local.prefix}-alb"
  description = "ALB (HTTP + test listener)"
  vpc_id      = var.vpc_id

  ingress {
    description = "Production HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.alb_ingress_cidr_ipv4]
  }

  ingress {
    description = "Test / Green verification"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.alb_ingress_cidr_ipv4]
  }

  egress {
    description = "Allow task traffic inside VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.this.cidr_block]
  }

  tags = merge(local.common_tags, { Name = "${local.prefix}-sg-alb" })
}

data "aws_vpc" "this" {
  id = var.vpc_id
}

resource "aws_security_group_rule" "ecs_tasks_from_alb" {
  type                     = "ingress"
  security_group_id        = var.ecs_tasks_security_group_id
  protocol                 = "tcp"
  from_port                = var.container_port
  to_port                  = var.container_port
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_lb" "public" {
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = merge(local.common_tags, { Name = "${local.prefix}-alb" })
}

resource "aws_lb_target_group" "blue" {
  name_prefix = substr(md5("${local.prefix}-blue"), 0, 6)
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }

  tags = merge(local.common_tags, { Name = "${local.prefix}-tg-blue" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "green" {
  name_prefix = substr(md5("${local.prefix}-green"), 0, 6)
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }

  tags = merge(local.common_tags, { Name = "${local.prefix}-tg-green" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "prod" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  tags = local.common_tags

  # CodeDeploy ECS blue/green reasigna el forward del listener al TG “vivo” al finalizar el deploy.
  lifecycle {
    ignore_changes = [default_action]
  }
}

resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.public.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [default_action]
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${local.prefix}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.fargate_cpu_architecture
  }

  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        for k in sort(keys(local.env_static)) : {
          name  = k
          value = local.env_static[k]
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "app"
        }
      }
    }
  ])

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_region" "current" {}

resource "aws_ecs_service" "app" {
  name            = "${local.prefix}-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_tasks_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = local.container_name
    container_port   = var.container_port
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.green.arn
    container_name   = local.container_name
    container_port   = var.container_port
  }

  # CodeDeploy actualiza task_definition y balanceadores; desired_count sí puede gestionarse desde Terraform
  # (evita confusión si escalas en tfvars; durante BG CodeDeploy sigue controlando los task sets).
  lifecycle {
    ignore_changes = [task_definition, load_balancer]
  }

  depends_on = [aws_lb_listener.prod, aws_lb_listener.test]
}

resource "aws_iam_role" "codedeploy" {
  name_prefix = "${local.prefix}-cd-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codedeploy.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "codedeploy_ecs" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

resource "aws_codedeploy_app" "ecs" {
  compute_platform = "ECS"
  name             = "${local.prefix}-codedeploy"

  tags = local.common_tags
}

resource "aws_codedeploy_deployment_group" "ecs" {
  app_name              = aws_codedeploy_app.ecs.name
  deployment_group_name = "${local.prefix}-dg"
  service_role_arn      = aws_iam_role.codedeploy.arn
  # Predefined ECS configs use names like CodeDeployDefault.ECSAllAtOnce (there is no ECSAllAtOnceBlueGreen).
  # See: https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-configurations.html
  deployment_config_name = var.codedeploy_deployment_config_name

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = "CONTINUE_DEPLOYMENT"
      wait_time_in_minutes = 0
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.this.name
    service_name = aws_ecs_service.app.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.prod.arn]
      }

      test_traffic_route {
        listener_arns = [aws_lb_listener.test.arn]
      }

      target_group {
        name = aws_lb_target_group.blue.name
      }

      target_group {
        name = aws_lb_target_group.green.name
      }
    }
  }
}

resource "aws_s3_bucket" "codedeploy_artifacts" {
  count  = var.create_codedeploy_artifact_bucket ? 1 : 0
  bucket = "${local.prefix}-codedeploy-artifacts-${data.aws_caller_identity.current.account_id}"

  tags = merge(local.common_tags, { Name = "${local.prefix}-codedeploy-artifacts" })
}

data "aws_caller_identity" "current" {}

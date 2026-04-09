locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  eb_name_prefix = "${var.project_name}-${var.environment}"
}

data "aws_elastic_beanstalk_solution_stack" "docker" {
  count = var.solution_stack_name == "" ? 1 : 0

  most_recent = true
  name_regex  = var.solution_stack_regex
}

locals {
  solution_stack = var.solution_stack_name != "" ? var.solution_stack_name : data.aws_elastic_beanstalk_solution_stack.docker[0].name
}

resource "aws_iam_role" "eb_service" {
  name_prefix = "${local.eb_name_prefix}-eb-svc-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "elasticbeanstalk.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "eb_service_health" {
  role       = aws_iam_role.eb_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

# Managed updates policy ARN is not available in all partitions/regions (IAM returns NoSuchEntity).
# EB runs without it; enable managed updates from the console later if your account exposes a policy.

resource "aws_iam_role_policy_attachment" "eb_service_core" {
  role       = aws_iam_role.eb_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

resource "aws_iam_role" "eb_ec2" {
  name_prefix = "${local.eb_name_prefix}-eb-ec2-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "eb_ec2_web_tier" {
  role       = aws_iam_role.eb_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "eb_ec2_docker" {
  role       = aws_iam_role.eb_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_instance_profile" "eb_ec2" {
  name_prefix = "${local.eb_name_prefix}-eb-ec2-"
  role        = aws_iam_role.eb_ec2.name

  tags = local.common_tags
}

resource "aws_elastic_beanstalk_application" "this" {
  name        = "${local.eb_name_prefix}-app"
  description = "Flask blacklist service (${var.environment})"

  tags = local.common_tags
}

resource "aws_elastic_beanstalk_environment" "this" {
  name                = "${local.eb_name_prefix}-env"
  application         = aws_elastic_beanstalk_application.this.name
  solution_stack_name = local.solution_stack
  tier                = "WebServer"

  # Individual settings avoid Terraform marking a whole map sensitive (which breaks dynamic for_each).
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_URL"
    value     = var.database_url
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "JWT_SECRET_KEY"
    value     = var.jwt_secret_key
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "JWT_EXPIRES_HOURS"
    value     = var.jwt_expires_hours
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SERVICE_USERNAME"
    value     = var.service_username
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SERVICE_PASSWORD"
    value     = var.service_password
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RUN_DB_INIT"
    value     = var.run_db_init
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_INIT_REQUIRED"
    value     = var.db_init_required
  }

  dynamic "setting" {
    for_each = var.extra_environment_variables
    content {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = setting.key
      value     = setting.value
    }
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.eb_service.arn
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = join(",", var.instance_security_group_ids)
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = tostring(var.min_size)
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = tostring(var.max_size)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = var.vpc_id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", var.private_subnet_ids)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = join(",", var.public_subnet_ids)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = var.associate_public_ip ? "true" : "false"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }

  # Target group must use port 80 on the instance (nginx); container port comes from Dockerfile EXPOSE.
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Port"
    resource  = "AWSEBV2LoadBalancerTargetGroup"
    value     = "80"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = var.health_check_path
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "MatcherHTTPCode"
    value     = "200"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "DeploymentPolicy"
    value     = var.deployment_policy
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSizeType"
    value     = var.deployment_batch_size_type
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSize"
    value     = var.deployment_batch_size
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "Timeout"
    value     = "1800"
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      version_label,
    ]
  }
}

locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_security_group" "eb_instances" {
  name        = "${var.project_name}-${var.environment}-eb-instances"
  description = "Elastic Beanstalk application instances"
  vpc_id      = var.vpc_id

  # ALB (same VPC) reaches nginx on 80; nginx proxies to the container (Dockerfile EXPOSE).
  ingress {
    description = "HTTP from VPC for load balancer to nginx"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Optional direct container port from VPC for debugging"
    from_port   = var.application_port
    to_port     = var.application_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description      = "All outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-sg-eb-instances" })
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds"
  description = "PostgreSQL RDS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Postgres from EB instances"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eb_instances.id]
  }

  egress {
    description      = "All outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-sg-rds" })
}

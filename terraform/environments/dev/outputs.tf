output "eb_cname" {
  value       = module.elastic_beanstalk.cname
  description = "HTTP endpoint for the Beanstalk environment (deploy app via EB/CI first)."
}

output "eb_application_name" {
  value = module.elastic_beanstalk.application_name
}

output "eb_environment_name" {
  value = module.elastic_beanstalk.environment_name
}

output "rds_endpoint" {
  value       = module.rds.endpoint
  description = "RDS hostname (credentials are sensitive; see Terraform state)."
}

output "vpc_id" {
  value = module.network.vpc_id
}

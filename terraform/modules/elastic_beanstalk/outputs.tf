output "application_name" {
  value       = aws_elastic_beanstalk_application.this.name
  description = "Elastic Beanstalk application name."
}

output "environment_name" {
  value       = aws_elastic_beanstalk_environment.this.name
  description = "Elastic Beanstalk environment name."
}

output "environment_id" {
  value       = aws_elastic_beanstalk_environment.this.id
  description = "Elastic Beanstalk environment ID."
}

output "cname" {
  value       = aws_elastic_beanstalk_environment.this.cname
  description = "Public URL hostname (HTTP) for the environment."
}

output "ec2_instance_profile_name" {
  value       = aws_iam_instance_profile.eb_ec2.name
  description = "Instance profile attached to EB instances."
}

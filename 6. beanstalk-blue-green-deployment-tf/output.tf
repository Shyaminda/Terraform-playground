output "application_name" {
  description = "Name of the Elastic Beanstalk application"
  value       = aws_elastic_beanstalk_application.app.name
}

output "blue_environment_name" {
  description = "Name of the Blue (Production) environment"
  value       = aws_elastic_beanstalk_environment.blue.name
}

output "blue_environment_url" {
  description = "URL of the Blue (Production) environment"
  value       = "http://${aws_elastic_beanstalk_environment.blue.cname}"
}

output "blue_environment_cname" {
  description = "CNAME of the Blue environment"
  value       = aws_elastic_beanstalk_environment.blue.cname
}

output "green_environment_name" {
  description = "Name of the Green (Staging) environment"
  value       = aws_elastic_beanstalk_environment.green.name
}

output "green_environment_url" {
  description = "URL of the Green (Staging) environment"
  value       = "http://${aws_elastic_beanstalk_environment.green.cname}"
}

output "green_environment_cname" {
  description = "CNAME of the Green environment"
  value       = aws_elastic_beanstalk_environment.green.cname
}

output "s3_bucket" {
  description = "S3 bucket for application versions"
  value       = aws_s3_bucket.app_versions.id
}

output "swap_command" {
  description = "AWS CLI command to swap environment CNAMEs"
  value       = <<-EOT
    aws elasticbeanstalk swap-environment-cnames \
      --source-environment-name ${aws_elastic_beanstalk_environment.blue.name} \
      --destination-environment-name ${aws_elastic_beanstalk_environment.green.name} \
      --region ${var.aws_region}
  EOT
}
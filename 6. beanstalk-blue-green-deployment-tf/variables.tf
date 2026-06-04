variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "The name of the Elastic Beanstalk application"
  type        = string
  default     = "my-beanstalk-app"
}

variable "tag" {
  description = "A tag to apply to all resources"
  type        = map(string)
  default     = {
    project = "beanstalk-blue-green-deployment"
    environment = "dev"
    managedBy = "terraform"
  }
}
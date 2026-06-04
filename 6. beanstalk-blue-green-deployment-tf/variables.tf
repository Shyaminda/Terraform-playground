variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = ""
}

variable "app_name" {
  description = "The name of the Elastic Beanstalk application"
  type        = string
  default     = ""
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

variable "solution_stack_name" {
  description = "The Elastic Beanstalk solution stack to use for the environment"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "The EC2 instance type for the Elastic Beanstalk environment"
  type        = string
  default     = ""
}
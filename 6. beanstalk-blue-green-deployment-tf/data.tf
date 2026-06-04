# Data source for current AWS account
data "aws_caller_identity" "current" {}

data "aws_elastic_beanstalk_solution_stack" "nodejs" {
  most_recent = true
  name_regex = "^64bit Amazon Linux.*running Node.js 20.*$"
}
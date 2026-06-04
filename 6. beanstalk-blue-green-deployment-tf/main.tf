resource "aws_iam_role" "eb_ec2_role" {
  name = "${var.app_name}-eb-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = var.tag
}

# Attach the AWS managed policy for Web Tier
resource "aws_iam_role_policy_attachment" "eb_web_tier" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

# Attach the AWS managed policy for Worker Tier
# The policy grants the permissions required for Worker Tier environments, such as consuming messages from SQS, writing logs to CloudWatch, and reporting health information to Elastic Beanstalk.
resource "aws_iam_role_policy_attachment" "eb_worker_tier" { //beanstalk consist of 2 tiers, web and worker
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

# Attach the AWS managed policy for Multicontainer Docker
# Allows the EC2 instances hosting the containers to interact with supporting AWS services, manage container workloads, and report health and monitoring information back to Elastic Beanstalk.
resource "aws_iam_role_policy_attachment" "eb_multicontainer_docker" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

# Instance Profile
# AWS EC2 instances cannot directly attach IAM roles, so an Instance Profile acts as the bridge that provides temporary AWS credentials to applications running on the instance.
resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "${var.app_name}-eb-ec2-profile"
  role = aws_iam_role.eb_ec2_role.name
  tags = var.tag
}

# IAM Role for Elastic Beanstalk Service
# The Elastic Beanstalk Service Role is an IAM role assumed by the Elastic Beanstalk service itself. It grants Beanstalk permissions to manage AWS resources such as EC2 instances, Auto Scaling Groups, Load Balancers, and CloudWatch components on behalf of the user.
resource "aws_iam_role" "eb_service_role" {
  name = "${var.app_name}-eb-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
      },
    ]
  })

  tags = var.tag
}

# Attach Enhanced Health Reporting policy
resource "aws_iam_role_policy_attachment" "eb_service_health" {
  role       = aws_iam_role.eb_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

# Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "app" {
  name        = var.app_name
  description = "Elastic Beanstalk application for blue-green deployment demo"
  tags        = var.tag
}

# S3 Bucket for application versions
resource "aws_s3_bucket" "app_versions" {
  bucket = "${var.app_name}-versions-${data.aws_caller_identity.current.account_id}"
  tags   = var.tag
}

# Block public access to S3 bucket
resource "aws_s3_bucket_public_access_block" "app_versions" {
  bucket = aws_s3_bucket.app_versions.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

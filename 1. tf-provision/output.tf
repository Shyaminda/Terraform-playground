output "bucket_name" {
	description = "Name of the created S3 bucket"
	value = aws_s3_bucket.demo_bucket.bucket
}

output "bucket_arn" {
	description = "ARN of the created S3 bucket"
	value = aws_s3_bucket.demo_bucket.arn
}

output "environment" {
	description = "Environment name"
	value = var.environment
}

output "tags" {
	description = "Common tags applied to resources"
	value = local.common_tags
}
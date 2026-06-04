resource "aws_s3_bucket" "demo_bucket" {
	bucket = local.full_bucket_name
	tags = local.common_tags
}
resource "aws_s3_bucket" "static_web_bucket" {
	bucket = var.bucket_name
}
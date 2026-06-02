resource "aws_s3_bucket" "static_web_bucket" {
	bucket = var.bucket_name
}

resource "aws_s3_public_access_block" "public_access_block" {
	bucket = aws_s3_bucket.static_web_bucket.id

	block_public_acls       = true
	block_public_policy     = true
	ignore_public_acls      = true
	restrict_public_buckets = true
}
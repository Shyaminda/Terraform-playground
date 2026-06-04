variable "environment" {
	type = string
	description = "Environment name"
	default = "staging"
}

variable "bucket_name" {
	type = string
	description = "Name of the S3 bucket to create"
	default = "tf-s3-provision-demo-bucket"
}
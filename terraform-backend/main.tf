terraform {
	/* this is done after the local state creation to bring the local state to the remote state for better 
	state management and collaboration */
	backend "s3" {
		bucket = "terraform-state-bucket-shyaminda"
		key = "terraform-playground/terraform-backend/terraform.tfstate"
		region = "us-east-1"
		dynamodb_table = "terraform-state-locking"
		encrypt = true
	}
	required_providers {
		aws = {
			source = "hashicorp/aws"
			version = "~> 5.0"
		}
	}
}
provider "aws" {
	region = "us-east-1"
}

/* Creates the S3 bucket that will store the Terraform state.
we can use any name for "terraform_state" */
resource "aws_s3_bucket" "terraform_state" {
	bucket = "terraform-state-bucket-shyaminda"  // Change this to a unique bucket name
	force_destroy = true
}

/* Enables versioning on the bucket. 
This is important for Terraform state safety: if the state file gets corrupted you can recover a previous version.
terraform_bucket_versioning can be any name */
resource "aws_s3_bucket_versioning" "terraform_bucket_versioning" {
	bucket = aws_s3_bucket.terraform_state.id
	versioning_configuration {
		status = "Enabled"
	}
}

/* Enables server-side encryption (SSE-S3, AES256) for objects in the bucket. Good security practice. */
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_bucket_encryption" {
	bucket = aws_s3_bucket.terraform_state.bucket
	rule {
		apply_server_side_encryption_by_default {
			sse_algorithm = "AES256"
		}
	}
}

resource "aws_dynamodb_table" "terraform_locks" {
	name = "terraform-state-locking"
	billing_mode = "PAY_PER_REQUEST"
	hash_key = "LockID"
	attribute {
		name = "LockID"
		type = "S"  // S = String
	}
}

//this will create 3 resources: S3 bucket, versioning for the bucket, DynamoDB table for state locking
/*after making the state remote the state file is saved inside the s3 bucket and dynamodb
store a tiny lock record so no one else can run apply at the same time */
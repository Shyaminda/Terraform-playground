terraform {
	backend "s3" {
		bucket = "tf-s3-provision-state-demo-bucket"
		key    = "dev/terraform.tfstate"
		region = "us-east-1"
		encrypt = true
		use_lockfile = true
	}
	required_providers {
		aws = {
			source  = "hashicorp/aws"
			version = "~> 6.0"
		}
	}
}

provider "aws" {
	region = "us-east-1"
}

# create s3 bucket
resource "aws_s3_bucket" "demo_bucket" {
	bucket = "tf-s3-provision-demo-bucket"
}
terraform {
	backend "s3" {
		bucket = "tf-s3-provision-state-demo-bucket"
		key    = "dev/terraform.tfstate"
		region = "us-east-1"
		encrypt = true
		use_lockfile = true
	}
}
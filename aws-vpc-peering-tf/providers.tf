terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = var.primary
}

provider "aws" {
	region = "us-west-2"
	alias  = var.secondary
}
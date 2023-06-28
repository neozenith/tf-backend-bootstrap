terraform {
  required_version = ">= 1.0.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
#defining the provider as aws
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

resource "aws_s3_bucket" "my_bucket_resource" {
  bucket = "${var.project}-${var.team}-${var.environment}-${var.aws_region}"
}
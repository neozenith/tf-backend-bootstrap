terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.7.0"
    }

  }
}

module "storage_s3" {
  source = "./storage/s3"

  providers = { aws = aws }
  aws_profile = var.aws_profile
  environment = var.environment
  project     = var.project
  team        = var.team

  instance_name = var.instance_name
  instance_url = var.instance_url
}

module "iam" {
  source = "./storage/iam"

  providers = { aws = aws }
  aws_profile = var.aws_profile
  environment = var.environment
  project     = var.project
  team        = var.team

  instance_name = var.instance_name
  s3_bucket = module.storage_s3.s3_bucket.bucket
  depends_on = [ module.storage_s3.s3_bucket ]
}
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.7.0"
    }

  }
}
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}


module "state_backend_s3_dynamo_db" {
  source    = "../../modules/state_backend_s3_dynamo_db"
  providers = { aws = aws }

  aws_profile = var.aws_profile
  environment = var.environment
  project     = var.project
  team        = var.team

  trusted_terraform_identity_arns = var.trusted_terraform_identity_arns


}
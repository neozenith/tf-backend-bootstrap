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

# module "vpc_jumpbox" {
#   source = "../../modules/vpc_jumpbox"
#   providers = { aws = aws }
#   aws_region = var.aws_region  
# }

module "state_backend_rds" {
  source    = "../../modules/state_backend_rds"
  providers = { aws = aws }
  # vpc_id         = var.vpc_id == null ? module.vpc_jumpbox.vpc_id : var.vpc_id # If an existing VPC id is provided then use that or create a VPC from scratch.

  aws_profile = var.aws_profile
  environment = var.environment
  project     = var.project
  team        = var.team
  # depends_on = [module.vpc_jumpbox]

}
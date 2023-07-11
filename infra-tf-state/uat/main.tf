provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

resource "aws_default_vpc" "default" {
}

module "state_backend_rds" {
  source      = "../../modules/state_backend_rds"
  vpc         = aws_default_vpc.default
  aws_profile = var.aws_profile
  environment = var.environment
  project     = var.project
  team        = var.team
}
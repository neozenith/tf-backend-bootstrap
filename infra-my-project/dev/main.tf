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


module "my_token_architecture" {
  source = "../../modules/my_token_architecture"

  for_each      = toset(var.instance_name_list)
  instance_name = each.key
  instance_url  = var.instance_url

  providers   = { aws = aws }
  aws_profile = var.aws_profile
  environment = var.environment
  project     = var.project
  team        = var.team

}
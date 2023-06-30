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


resource "aws_kms_key" "tf_rds_backend" {
  description = "tf_rds_backend KMS Key"
}

resource "aws_db_instance" "tf_rds_backend" {
  allocated_storage     = 5
  max_allocated_storage = 10
  storage_encrypted     = true
  db_name               = "tf_rds_backend_${var.environment}"
  engine                = "postgres"
  # engine_version                = "14.1"
  instance_class                = "db.t3.micro"
  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.tf_rds_backend.key_id
  username                      = "tf_state_rds_backend_admin"

  # These settings should be removed for prd
  publicly_accessible = true
  skip_final_snapshot = true

}
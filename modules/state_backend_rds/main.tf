terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.7.0"
    }

  }
}

resource "aws_kms_key" "tf_rds_backend" {
  description = "tf_rds_backend KMS Key"
}

resource "aws_security_group" "rds" {
  name   = "terraform-psql-rds-backend"
  vpc_id = var.vpc_id == null ? aws_default_vpc.default.id : var.vpc_id

}

resource "aws_vpc_security_group_ingress_rule" "rds_ingress" {
  security_group_id = aws_security_group.rds.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 5432
  ip_protocol = "tcp"
  to_port     = 5432
}
resource "aws_vpc_security_group_egress_rule" "rds_egress" {
  security_group_id = aws_security_group.rds.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 5432
  ip_protocol = "tcp"
  to_port     = 5432
}

resource "aws_db_instance" "tf_rds_backend" {
  allocated_storage     = 20
  max_allocated_storage = 40
  storage_encrypted     = true
  db_name               = "tf_rds_backend_${var.environment}"
  engine                = "postgres"
  # engine_version                = "14.7"
  instance_class = "db.t3.micro"

  # Security Settings
  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.tf_rds_backend.key_id
  username                      = "tf_state_rds_backend_admin"
  vpc_security_group_ids        = [aws_security_group.rds.id]


  # These settings should be removed for prd
  publicly_accessible = true
  skip_final_snapshot = true
  apply_immediately   = true

}
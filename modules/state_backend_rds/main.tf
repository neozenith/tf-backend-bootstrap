provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}


resource "aws_kms_key" "tf_rds_backend" {
  description = "tf_rds_backend KMS Key"
}

resource "aws_security_group" "rds" {
  name   = "terraform-psql-rds-backend"
  vpc_id = var.vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
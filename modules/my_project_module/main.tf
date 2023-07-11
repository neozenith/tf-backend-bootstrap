terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.7.0"
    }

  }
}

resource "aws_s3_bucket" "main_bucket" {

  bucket_prefix = "${var.project}-${var.instance_name}-${var.environment}-"
  force_destroy = var.environment == "dev"
  tags = {
    Project     = var.project
    Environment = var.environment
    Name = var.instance_name
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main_bucket_s3_sse_config" {
  bucket = aws_s3_bucket.main_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
  depends_on = [aws_s3_bucket.main_bucket]
}
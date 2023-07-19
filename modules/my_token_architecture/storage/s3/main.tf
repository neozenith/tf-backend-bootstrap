
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

  bucket        = "${var.project}-${var.environment}-${var.instance_name}"
  force_destroy = var.environment == "dev"
  tags = {
    Name       = "${var.instance_name} S3 Storage"
    clientname = var.instance_name
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


resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.main_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "AWS_S3_SECURE_TRANSPORT"
    Statement = [
      {
        Sid       = "AllowSSLRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "${aws_s3_bucket.main_bucket.arn}",
          "${aws_s3_bucket.main_bucket.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
  depends_on = [aws_s3_bucket.main_bucket]
}

resource "aws_s3_bucket_cors_configuration" "main_bucket_cors_config" {
  bucket = aws_s3_bucket.main_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "DELETE"]
    allowed_origins = [var.instance_url]
    expose_headers  = []
    max_age_seconds = 3000
  }

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }

  depends_on = [aws_s3_bucket.main_bucket]
}

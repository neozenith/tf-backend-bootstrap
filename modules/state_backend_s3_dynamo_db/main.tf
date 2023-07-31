
resource "aws_s3_bucket" "main_bucket" {

  bucket        = "terraform-state-${var.project}-${var.environment}"
  force_destroy = true # var.environment == "dev"
  tags = {
    Name       = "${var.project} S3 Storage"
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

resource "aws_s3_bucket_versioning" "main_bucket" {
  bucket = aws_s3_bucket.main_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}


# https://github.com/trussworks/terraform-aws-bootstrap/blob/main/main.tf#L56-L77
# https://developer.hashicorp.com/terraform/language/settings/backends/s3#dynamodb-state-locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name     = "terraform-state-${var.project}-${var.environment}"
  hash_key = "LockID"

  billing_mode = "PAY_PER_REQUEST"

  server_side_encryption {
    enabled = true
  }

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true # var.dynamodb_point_in_time_recovery
  }

  # tags = var.dynamodb_table_tags
}
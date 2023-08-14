# https://github.com/trussworks/terraform-aws-bootstrap/blob/main/main.tf#L56-L77
# https://developer.hashicorp.com/terraform/language/settings/backends/s3#dynamodb-state-locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name     = var.dynamodb_table_name
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
    enabled = var.dynamodb_point_in_time_recovery
  }

  tags = var.dynamodb_table_tags
}
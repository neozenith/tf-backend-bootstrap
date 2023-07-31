output "aws_profile" {
  value      = var.aws_profile
  depends_on = [var.aws_profile]
}

output "aws_region" {
  value      = var.aws_region
  depends_on = [var.aws_region]
}

output "backend_details" {
  value = {
    s3_bucket = module.state_backend_s3_dynamo_db.s3_bucket.bucket
    dynamodb_table = module.state_backend_s3_dynamo_db.dynamodb_table
  }
}
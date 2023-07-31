output "s3_bucket" {
  value = aws_s3_bucket.main_bucket

}

output "dynamodb_table" {
  value = aws_dynamodb_table.terraform_state_lock.name

}
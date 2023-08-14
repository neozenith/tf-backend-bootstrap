output "s3_bucket" {
  value = aws_s3_bucket.main_bucket
}

output "terraform_state_file_key" {
  value = local.terraform_state_file_key
}

output "dynamodb_table" {
  value = aws_dynamodb_table.terraform_state_lock.name

}

output "aws_terraform_role_arn" {
  value = aws_iam_role.role.arn
}

output "aws_terraform_credentials" {
  value = {
    profile_name     = local.output_terraform_credential_profile_name
    credentials_path = local.terraform_state_credentials_path,
    credentials_file = "${local.terraform_state_credentials_path}/credentials"
  }
}
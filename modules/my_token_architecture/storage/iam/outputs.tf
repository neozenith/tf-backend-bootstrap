output "iam_user" {
  value =  aws_iam_user.user
}

output "iam_access_key" {
  value = aws_iam_access_key.access_key
}

output "iam_role" {
  value = aws_iam_role.role
}

# output "s3_role_policy_document" {
#   value = data.aws_iam_policy_document.s3_role_policy_document.json
# }

# output "assume_role_policy_document" {
#   value = data.aws_iam_policy_document.assume_role_policy_document.json
# }
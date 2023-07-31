output "aws_profile" {
  value      = var.aws_profile
  depends_on = [var.aws_profile]
}

output "aws_region" {
  value      = var.aws_region
  depends_on = [var.aws_region]
}


output "s3_buckets" {
  value = { for b in sort(toset(var.instance_name_list)) : b => module.my_token_architecture[b].s3_bucket }
}


output "iam_user" {
  value = { for b in sort(toset(var.instance_name_list)) : b => module.my_token_architecture[b].iam_user }
}

output "iam_access_key" {

  value     = { for b in sort(toset(var.instance_name_list)) : b => module.my_token_architecture[b].iam_access_key }
  sensitive = true
}

output "iam_role" {
  value = { for b in sort(toset(var.instance_name_list)) : b => module.my_token_architecture[b].iam_role }
}

# output "assume_role_policy_document" {
#   value       = { for b in sort(toset(var.instance_name_list)) : b => module.my_token_architecture[b].assume_role_policy_document } 
# }

# output "s3_role_policy_document" {
#   value       = { for b in sort(toset(var.instance_name_list)) : b => module.my_token_architecture[b].s3_role_policy_document } 
# }


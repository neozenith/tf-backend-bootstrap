output "s3_bucket" {
  value = module.storage_s3.s3_bucket.bucket

}

output "iam_user" {
  value =  module.iam.iam_user
}

output "iam_access_key" {
  value = module.iam.iam_access_key
}

output "iam_role" {
  value = module.iam.iam_role
}

# output "s3_role_policy_document" {
#   value = module.iam.s3_role_policy_document
# }

# output "assume_role_policy_document" {
#   value = module.iam.assume_role_policy_document
# }
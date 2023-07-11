output "aws_profile" {
  value      = var.aws_profile
  depends_on = [var.aws_profile]
}

output "aws_region" {
  value      = var.aws_region
  depends_on = [var.aws_region]
}


output "s3_buckets" {
  value       = { for b in sort(toset(var.instance_name_list)) : b => module.my_project_module[b].s3_bucket_name }
  
}
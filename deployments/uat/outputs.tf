output "aws_profile" {
  value      = var.aws_profile
  depends_on = [var.aws_profile]
}

output "aws_region" {
  value      = var.aws_region
  depends_on = [var.aws_region]
}

output "rds_backend" {
  value = module.state_backend_rds
}
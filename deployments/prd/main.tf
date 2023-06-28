module "state_backend_rds" {
    source = "../../modules/state_backend_rds"
    aws_profile = var.aws_profile
    environment = var.environment
    project = var.project
    team = var.team
}
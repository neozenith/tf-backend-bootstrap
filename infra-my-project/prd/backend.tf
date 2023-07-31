terraform {

# TODO: Assume Role - https://developer.hashicorp.com/terraform/language/settings/backends/s3#assume-role-configuration
  backend "s3" {
    profile = "joshpeak-prd"
    bucket = "terraform-state-tf-backend-bootstrap-prd"
    key    = "terraform.tfstate"
    encrypt = true
    dynamodb_table = "terraform-state-tf-backend-bootstrap-prd"
    region = "ap-southeast-2"
  }
}
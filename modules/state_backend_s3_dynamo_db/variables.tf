// Input Variables
// https://developer.hashicorp.com/terraform/language/values/variables#using-input-variable-values
//
// There are many ways to inject input variables to parameterise infrastructure definitions. Please read the terraform docs and understand them.

variable "trusted_terraform_identity_arns" {
  description = "List of ARN identifiers to add to the trust relationship of the terraform role."
  type        = list(string)
  nullable    = false
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB Table for locking Terraform state."
  default     = "terraform-state-lock"
  type        = string
}

variable "dynamodb_table_tags" {
  description = "Tags of the DynamoDB Table for locking Terraform state."
  default = {
    Name       = "terraform-state-lock"
    Automation = "Terraform"
  }
  type = map(string)
}

variable "dynamodb_point_in_time_recovery" {
  type        = bool
  default     = true
  description = "Point-in-time recovery options"
}
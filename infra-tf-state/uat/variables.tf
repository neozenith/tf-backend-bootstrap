// Input Variables
// https://developer.hashicorp.com/terraform/language/values/variables#using-input-variable-values
//
// There are many ways to inject input variables to parameterise infrastructure definitions. Please read the terraform docs and understand them.

variable "trusted_terraform_identity_arns" {
  description = "List of ARN identifiers to add to the trust relationship of the terraform role."
  type        = list(string)
  nullable    = false
}

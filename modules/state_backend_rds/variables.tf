// Input Variables
// https://developer.hashicorp.com/terraform/language/values/variables#using-input-variable-values
//
// There are many ways to inject input variables to parameterise infrastructure definitions. Please read the terraform docs and understand them.

variable "vpc_id" {
  description = "Target VPC for deployment. Defaults to default vpc for a region if not specified."
  nullable    = true
  default     = null
}


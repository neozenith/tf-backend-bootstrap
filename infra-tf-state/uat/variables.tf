// Input Variables
// https://developer.hashicorp.com/terraform/language/values/variables#using-input-variable-values
//
// There are many ways to inject input variables to parameterise infrastructure definitions. Please read the terraform docs and understand them.


variable "vpc_id" {
  description = "Optional VPC ID if wanting to target an existing VPC. If this is omitted then one will be created and it's id will be an output."
  nullable    = true
  default     = null
}


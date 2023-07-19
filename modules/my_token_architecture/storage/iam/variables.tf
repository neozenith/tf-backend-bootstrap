// Input Variables
// https://developer.hashicorp.com/terraform/language/values/variables#using-input-variable-values
//
// There are many ways to inject input variables to parameterise infrastructure definitions. Please read the terraform docs and understand them.

variable "instance_name" {
  description = "Instance name to assist configuring which client instance this deployment of this module belongs to"
  nullable    = false
  type        = string
}


variable "s3_bucket" {
  description = "Name of bucket to grant access to"
  nullable    = false
  type        = string

}
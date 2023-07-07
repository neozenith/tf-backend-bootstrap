// Input Variables
// https://developer.hashicorp.com/terraform/language/values/variables#using-input-variable-values
//
// There are many ways to inject input variables to parameterise infrastructure definitions. Please read the terraform docs and understand them.

// AWS
// this assumes you have locally configured a named `profile` in ~/.aws/.credentials
// https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html
variable "aws_profile" {
  type     = string
  default  = "default"
  nullable = false

}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-southeast-2"
  nullable    = false
}

variable "vpc" {
  description = "Target VPC for deployment"
}

variable "environment" {
  description = "Deployment Environment AWS Account. dev/uat/prd"
  type        = string
  nullable    = false
  validation {
    condition     = contains(["dev", "uat", "prd"], var.environment)
    error_message = "The environment must be one of 'dev', 'uat', 'prd'."
  }
}

// TAGS
// Required Tags

variable "project" {
  // export TF_VAR_project
  description = "Name of the project that should appear in tagged resources."
  type        = string
  nullable    = false
}
variable "team" {
  // export TF_VAR_team 
  description = "Name of the owning team that should appear in tagged resources."
  type        = string
  nullable    = false
}


// Optional Tags with Defaults
variable "createdby" {
  // export TF_VAR_createdby=$(git config user.email)
  description = "The user or service that created the infrastructure components"
  default     = "terraform"
  nullable    = false
}


variable "additional_tags" {
  default = { "owner" : "terraform" }
}

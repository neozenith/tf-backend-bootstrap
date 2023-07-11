variable "aws_region" {}
variable "main_vpc_cidr" { default = "10.0.0.0/24" }
variable "public_subnets" { default = "10.0.0.128/26" }
variable "private_subnets" { default = "10.0.0.192/26" }

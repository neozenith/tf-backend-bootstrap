# Create the resource to reference the default VPC 
# If a specific VPC is not created and passed into the module then we use this one.

resource "aws_default_vpc" "default" {
}
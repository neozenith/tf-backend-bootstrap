# Terraform State Backend - RDS PostgreSQL

This terraform module will bootstrap setting up and RDS PostgreSQL instance in 
a target AWS account using a local backend initially. We will then transfer
state management to the RDS instance using the [`pg`](https://developer.hashicorp.com/terraform/language/settings/backends/pg) backend.

## Quickstart

You will want to copy `terraform.tfvars.example` into each of:
 - `deployments/dev/terraform.tfvars`
 - `deployments/uat/terraform.tfvars`
 - `deployments/prd/terraform.tfvars`

And modify the values accordingly:

`terraform.tfvars`

```sh
environment = "dev"
aws_profile = "my-dev-aws-profile"
team = "hobbyprojects"
project = "tf-backend-bootstrap"
```

Then from the root of the repo we can setup up each environment:

### Dev

```sh
terraform -chdir=deployments/dev init
terraform -chdir=deployments/dev plan
terraform -chdir=deployments/dev apply -auto-approve
```

### UAT

```sh
terraform -chdir=deployments/uat init
terraform -chdir=deployments/uat plan
terraform -chdir=deployments/uat apply -auto-approve
```

### PRD

```sh
terraform -chdir=deployments/prd init
terraform -chdir=deployments/prd plan
terraform -chdir=deployments/prd apply -auto-approve
```
# Terraform State Backend Experiments

We will deploy the same setup to 3 distinct AWS accounts each with their own isolated state management.


<!--TOC-->

- [Terraform State Backend Experiments](#terraform-state-backend-experiments)
  - [Quickstart](#quickstart)
    - [Setup the tfvars](#setup-the-tfvars)
    - [Python Scripts](#python-scripts)

<!--TOC-->

## Quickstart

### Setup the tfvars

You will want to copy `terraform.tfvars.example` into each of:
 - `infra-<target>/dev/terraform.tfvars`
 - `infra-<target>/uat/terraform.tfvars`
 - `infra-<target>/prd/terraform.tfvars`

And modify the values accordingly:

`terraform.tfvars`

```sh
environment = "dev"
aws_profile = "my-dev-aws-profile"
team = "hobbyprojects"
project = "tf-backend-bootstrap"
```

### Python Scripts

We are using `invoke` to help automate some of the more verbose scripts.

```sh
poetry install
poetry shell
invoke --list

```

Some example usage:

```sh
# SETUP STATE MANAGEMENT BACKEND
inv init dev infra-tf-state
inv plan dev infra-tf-state
inv apply dev infra-tf-state

# DEPLOY OUR MANAGED INFRASTRUCTURE
inv init dev infra-my-project
inv plan dev infra-my-project
inv apply dev infra-my-project

##################################

# CLEANUP OUR MANAGED INFRASTRUCTURE
inv destroy dev infra-my-project

# CLEAN UP RDS STATE MANAGEMENT
inv destroy dev infra-tf-state
```

The same applies for `dev`, `uat`, `prd`.

The specifics are located in `tasks.py`
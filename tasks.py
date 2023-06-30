# Standard Library
import json
import os
from pathlib import Path
from pprint import pprint as pp

# Third Party
import boto3
from invoke import task
from invoke_common_tasks import *  # noqa

VALID_ENVS = ["dev", "uat", "prd"]
standard_runner_kwargs = dict(pty=True, echo=True)


def validate_env(env):
    """Validate deployment environment name."""
    if env.lower() not in VALID_ENVS:
        raise ValueError(f"Specified environment '{env}' is not valid. Value must be one of {VALID_ENVS}")


@task
def tf(c, env: str, command: str):
    """Standardised terraform command runner for multiple environment states."""
    validate_env(env)
    c.run(f"terraform -chdir=deployments/{env} {command}", **standard_runner_kwargs)


@task
def tffmt(c, check=False):
    """Standardised terraform formatter for multiple environment states."""
    check_str = "-check" if check else ""
    c.run(f"terraform fmt -recursive -list=true {check_str}", **standard_runner_kwargs)


def _tf_output_json(c, env: str, key: str = None):
    """Standardised terraform output for multiple environment states."""
    validate_env(env)
    result = c.run(f"terraform -chdir=deployments/{env} output -json", hide=True)
    result_json = json.loads(result.stdout)
    if key:
        return result_json[key]["value"]
    else:
        return result_json


@task
def tfj(c, env: str):
    validate_env(env)
    c.run(f"terraform -chdir=deployments/{env} output -json | jq .", pty=True)


def aws_profile(c, env: str):
    """Extract the used AWS Profile from deployment environments input tfvars."""
    return _tf_output_json(c, env, "aws_profile")


def aws_region(c, env: str):
    """Extract the used AWS Region from deployment environments input tfvars."""
    return _tf_output_json(c, env, "aws_region")


@task
def init(c, env: str):
    """Initialise Terraform for the given deployment enviroment."""
    tf(c, env, "init")


@task
def plan(c, env: str):
    """Plan Terraform state change for the given deployment enviroment."""
    tf(c, env, "plan")


@task
def apply(c, env: str):
    """Apply Terraform state change for the given deployment enviroment."""
    tf(c, env, "apply -auto-approve")


@task
def refresh(c, env: str):
    """Plan Terraform state change for the given deployment enviroment."""
    tf(c, env, "refresh")


@task
def destroy(c, env: str):
    """Apply Terraform state change for the given deployment enviroment."""
    tf(c, env, "apply -destroy -auto-approve")


@task
def conn_str(c, env: str):
    """Generate the current connection string to the database."""
    tf_outputs = _tf_output_json(c, env)
    host = tf_outputs["rds_backend"]["value"]["rds_hostname"]
    user = tf_outputs["rds_backend"]["value"]["rds_username"]
    rds_secret = tf_outputs["rds_backend"]["value"]["rds_managed_secret"][0]

    # Password is managed by AWS and rotated weekly
    # So we need to securely retrieve it and compose the current connection string
    session = boto3.session.Session(profile_name=aws_profile(c, env))
    client = session.client(
        service_name="secretsmanager",
        region_name=aws_region(c, env),
    )
    secret = client.get_secret_value(SecretId=rds_secret["secret_arn"])

    password = json.loads(secret["SecretString"])["password"]
    connection_string = f"postgres://{user}:{password}@{host}/terraform_backend"
    export_statement = f"export PG_CONN_STR={connection_string}"
    print(export_statement)


@task
def create_backend(c, env: str):
    """Create a backend block for the target deployment environment."""
    validate_env(env)
    target_hcl_content = 'terraform {\nbackend "pg" {}\n}'
    target_path = Path(f"deployments/{env}/backend.tf")
    target_path.write_text(target_hcl_content)


@task
def remove_backend(c, env: str):
    """Remove a backend block for the target deployment environment."""
    validate_env(env)
    target_path = Path(f"deployments/{env}/backend.tf")
    if target_path.exists():
        os.remove(target_path)


@task
def toc(c):
    """Automate documentation tasks."""
    c.run("md_toc --in-place github --header-levels 4 README.md")


@task
def inframap(c, env: str):
    """Generate InfrMap architecture diagram."""
    validate_env(env)
    c.run(
        f"inframap generate deployments/{env}/terraform.tfstate --clean=false --connections=false | dot -Tpng > deployments/{env}/graph.png"
    )


@task
def all_bootstrap(c):
    """Destroy all resources in all environments."""
    for env in VALID_ENVS:
        apply(c, env)


@task
def all_migrate(c):
    """Destroy all resources in all environments."""
    for env in VALID_ENVS:
        ...


@task
def all_down(c):
    """Destroy all resources in all environments."""
    for env in VALID_ENVS:
        destroy(c, env)

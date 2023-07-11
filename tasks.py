# Standard Library
import json
import os
from pathlib import Path

# Third Party
import boto3
from invoke import task
from invoke_common_tasks import ci, format, init_config, lint, typecheck  # noqa

VALID_ENVS = ["dev", "uat", "prd"]
TF_STATE_PATH = "infra-tf-state"
TF_PROJECT = "infra-my-project"
standard_runner_kwargs = dict(pty=True, echo=True)


def validate_env(env):
    """Validate deployment environment name."""
    if env.lower() not in VALID_ENVS:
        raise ValueError(f"Specified environment '{env}' is not valid. Value must be one of {VALID_ENVS}")


@task
def tf(c, env: str, target: str, command: str):
    """Standardised terraform command runner for multiple environment states."""
    validate_env(env)
    target_path = Path(target) / env
    c.run(f"terraform -chdir={target_path} {command}", **standard_runner_kwargs)


def _tf_output_json(c, env: str, target: str, key: str = None):
    """Standardised terraform output for multiple environment states."""
    validate_env(env)
    target_path = Path(target) / env
    result = c.run(f"terraform -chdir={target_path} output -json", hide=True)
    result_json = json.loads(result.stdout)
    if key:
        return result_json[key]["value"]
    else:
        return result_json


def aws_profile(c, env: str, target: str):
    """Extract the used AWS Profile from deployment environments input tfvars."""
    return _tf_output_json(c, env, target, "aws_profile")


def aws_region(c, env: str, target: str):
    """Extract the used AWS Region from deployment environments input tfvars."""
    return _tf_output_json(c, env, target, "aws_region")


@task
def init(c, env: str, target: str):
    """Initialise Terraform for the given deployment enviroment."""
    tf(c, env, target, "init")


@task
def plan(c, env: str, target: str):
    """Plan Terraform state change for the given deployment enviroment."""
    tf(c, env, target, "plan")


@task
def apply(c, env: str, target: str):
    """Apply Terraform state change for the given deployment enviroment."""
    tf(c, env, target, "apply -auto-approve")


@task
def create_backend(c, env: str, target: str):
    """Create a backend block for the target deployment environment."""
    validate_env(env)
    target_hcl_content = 'terraform {\nbackend "pg" {}\n}'
    target_path = Path(target) / env / "backend.tf"
    target_path.write_text(target_hcl_content)


@task
def remove_backend(c, env: str, target: str):
    """Remove a backend block for the target deployment environment."""
    validate_env(env)
    target_path = Path(target) / env / "backend.tf"
    if target_path.exists():
        os.remove(target_path)


@task
def migrate_state(c, env: str, target: str):
    """Migrate Terraform state to a new provider."""
    tf(c, env, target, "init -migrate-state")


@task
def destroy(c, env: str, target: str):
    """Apply Terraform state change for the given deployment enviroment."""
    tf(c, env, target, "apply -destroy -auto-approve")


@task
def conn_str(c, env: str, target: str, save_shell_script: bool = False):
    """Generate the current connection string to the database."""
    tf_outputs = _tf_output_json(c, env, target)
    host = tf_outputs["rds_backend"]["value"]["rds_hostname"]
    user = tf_outputs["rds_backend"]["value"]["rds_username"]
    db_name = tf_outputs["rds_backend"]["value"]["rds_database_name"]

    # Secrets Manager - Managed Master Password rotates weekly by default.
    rds_secret = tf_outputs["rds_backend"]["value"]["rds_managed_secret"][0]
    connection_details = {
        "PGUSER": user,
        "PGHOST": host,
        "PGDATABASE": db_name,
        "RDS_SECRET_ARN": rds_secret["secret_arn"],
    }

    base_script = f"""
    # !!!NOTE: DO NOT USE PG_CONN_STR - The password will often not escape correctly in commandlines!!!
    # https://www.postgresql.org/docs/current/libpq-envars.html
    export PGUSER="{connection_details['PGUSER']}"
    export PGHOST="{connection_details['PGHOST']}"
    export PGDATABASE="{connection_details['PGDATABASE']}"
    export RDS_SECRET_ARN="{connection_details['RDS_SECRET_ARN']}"
    export AWS_REGION="{aws_region(c,env, target)}"
    export AWS_PROFILE="{aws_profile(c, env, target)}"
    export PGPASSWORD="$(aws secretsmanager get-secret-value --secret-id $RDS_SECRET_ARN --profile $AWS_PROFILE --region $AWS_REGION --output json | jq -r .SecretString | jq -r .password)"
    """

    print(base_script)
    if save_shell_script:
        path = Path(f"pgconstr-{target}-{env}.sh")
        path.write_text(base_script)

    return connection_details


def _get_secret_value(secret_arn, profile, region):
    """Fetch an AWS secret."""
    # Password is managed by AWS and rotated weekly
    # So we need to securely retrieve it and compose the current connection string
    session = boto3.session.Session(profile_name=profile)
    client = session.client(
        service_name="secretsmanager",
        region_name=region,
    )
    secret = client.get_secret_value(SecretId=secret_arn)
    return json.loads(secret["SecretString"])["password"]


@task
def bootstrap(c, env: str):
    """Bootsrap and environment."""
    target = TF_STATE_PATH
    init(c, env, target)
    apply(c, env, target)
    connection_details = conn_str(c, env, target, save_shell_script=True)
    connection_details["PGPASSWORD"] = _get_secret_value(
        secret_arn=connection_details["RDS_SECRET_ARN"],
        profile=aws_profile(c, env, target),
        region=aws_region(c, env, target),
    )
    create_backend(c, env, target)
    migrate_state(c, env, target)


@task
def unstrap(c, env: str):
    """Tear down and clean up the whole project."""
    target = TF_STATE_PATH
    # Remove reference that the backend is `pg` so it defaults to `local` again
    remove_backend(c, env, target)
    # Migrate from `pg` to `local`
    migrate_state(c, env, target)
    # Using the state in local, now tear it down.
    destroy(c, env, target)


########################### MISCELLANEOUS ########################### # noqa


@task
def toc(c):
    """Automate documentation tasks."""
    c.run("md_toc --in-place github --header-levels 4 README.md")


@task
def tffmt(c, check=False):
    """Standardised terraform formatter for multiple environment states."""
    check_str = "-check" if check else ""
    c.run(f"terraform fmt -recursive -list=true {check_str}", **standard_runner_kwargs)


@task
def inframap(c, env: str):
    """Generate InfrMap architecture diagram."""
    validate_env(env)
    c.run(
        f"inframap generate infra-tf-state/{env}/terraform.tfstate --clean=false --connections=false | dot -Tpng > graph.png"
    )


@task(pre=[format, toc, tffmt, lint, typecheck])
def tidy(c):
    """Run all quality checks."""
    ...

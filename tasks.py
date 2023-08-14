# Standard Library
import json
import os
import time
from pathlib import Path

# Third Party
from invoke import task
from invoke_common_tasks import ci, format, init_config, lint, typecheck  # noqa

VALID_ENVS = ["dev", "uat", "prd"]
TF_STATE_PATH = "infra-tf-state"
TF_PROJECT = "infra-my-project"
VALID_TARGETS = [TF_STATE_PATH, TF_PROJECT]
standard_runner_kwargs = dict(pty=True, echo=True)
CYCLE_OPTIONS = ["UP", "DOWN", "FULL"]


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
def migrate_state(c, env: str, target: str):
    """Migrate Terraform state to a new provider."""
    tf(c, env, target, "init -migrate-state")


@task
def reconfigure(c, env: str, target: str):
    """Migrate Terraform state to a new provider."""
    tf(c, env, target, "init -reconfigure")


@task
def destroy(c, env: str, target: str):
    """Apply Terraform state change for the given deployment enviroment."""
    tf(c, env, target, "apply -destroy -auto-approve")


@task(iterable=["env_list", "target_list"])
def cycle(
    c,
    env_list=None,
    target_list=None,
    cycle="FULL",
    migrate_backend=False,
    reconfigure_backend=False,
    local_only=False,
    sleep_sec=20,
):  # noqa: C901
    """Run through a IaC cycle setting up and tearing down for all envs of a subset of the combinations.

    env_list - Default is to perform the same cycle on envs unless a single env name or a list of env names provided.
    target_list - Default is to perform the same cycle on all targets unless a single target or a list of targets provided.
    cycle - A cycle is either "FULL" (default) which will perform an "UP" and then a "DOWN". Or you could specify only one half of the cycle.
    """
    if not env_list:
        env_list = VALID_ENVS
    elif type(env_list) == str:
        env_list = [env_list]

    if not target_list:
        target_list = VALID_TARGETS
    elif type(target_list) == str:
        target_list = [target_list]

    for target in target_list:
        for env in env_list:
            if cycle in ["UP", "FULL"]:
                # INIT
                if reconfigure_backend:
                    reconfigure(c, env, target)
                elif migrate_backend:
                    migrate_state(c, env, target)
                else:
                    init(c, env, target)

                # APPLY
                apply(c, env, target)
                if not local_only and target == TF_STATE_PATH:
                    create_backend(c, env)
                    print(f"Sleeping for {sleep_sec} seconds to ensure roles are created correctly...")
                    time.sleep(sleep_sec)
                    reconfigure(c, env, TF_PROJECT)

    for target in target_list[::-1]:
        for env in env_list:
            if cycle in ["DOWN", "FULL"]:
                destroy(c, env, target)
                if not local_only and target == TF_STATE_PATH:
                    remove_backend(c, env)
                    reconfigure(c, env, TF_PROJECT)


@task
def create_backend(c, env: str):
    """Using the outputs of infra-tf-state create a backend.tf for infra-my-project."""
    validate_env(env)
    region = _tf_output_json(c, env, TF_STATE_PATH, "aws_region")
    backend = _tf_output_json(c, env, TF_STATE_PATH, "backend_details")
    credentials_root_path = str(Path(TF_STATE_PATH) / env)

    target_hcl_content = f"""
terraform {{
  backend "s3" {{
    shared_credentials_file = "../../{credentials_root_path}/{backend['terraform_user_credentials']['credentials_file']}"

    profile = "{backend['terraform_user_credentials']['profile_name']}"
    region = "{region}"
    role_arn = "{backend['role_arn']}"

    bucket = "{backend['s3_bucket']}"
    key    = "{backend['s3_key']}"
    encrypt = true

    dynamodb_table = "{backend['dynamodb_table']}"
  }}
}}
    """

    target_path = Path(TF_PROJECT) / env / "backend.tf"
    target_path.write_text(target_hcl_content)


@task
def remove_backend(c, env: str):
    """Remove a backend block for the target deployment environment."""
    validate_env(env)
    target_path = Path(TF_PROJECT) / env / "backend.tf"
    if target_path.exists():
        os.remove(target_path)


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
def inframap(c, env: str, target: str):
    """Generate InfrMap architecture diagram."""
    validate_env(env)
    target_path = Path(target) / env
    state_file = target_path / "terraform.tfstate"

    c.run(f"inframap generate {state_file} --clean=false --connections=true | dot -Tpng > graph.png")


@task(pre=[format, toc, tffmt, lint, typecheck])
def tidy(c):
    """Run all quality checks."""
    ...

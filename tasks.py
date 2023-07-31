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
def destroy(c, env: str, target: str):
    """Apply Terraform state change for the given deployment enviroment."""
    tf(c, env, target, "apply -destroy -auto-approve")



@task(iterable=['env_list','target_list'])
def cycle(c, env_list = None, target_list = None, cycle = "FULL"):
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
                init(c, env, target)
                apply(c, env, target)

    for target in target_list[::-1]:
        for env in env_list:
            if cycle in ["DOWN", "FULL"]:
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

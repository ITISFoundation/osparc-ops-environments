import asyncio
import logging
import tempfile
from enum import IntEnum
from pathlib import Path
from shutil import copy2
from typing import Dict, List

import yaml
from aiohttp import ClientError, web
from servicelib.application_keys import APP_CONFIG_KEY
from yarl import URL
from tenacity import before_sleep_log, retry, stop_after_attempt, wait_fixed, retry_if_exception_type

from . import portainer
from .cmd_utils import run_cmd_line
from .docker_registries_watcher import DockerRegistriesWatcher
from .exceptions import ConfigurationError, DependencyNotReadyError
from .git_url_watcher import GitUrlWatcher
from .notifier import notify
from .subtask import SubTask

log = logging.getLogger(__name__)
TASK_NAME = __name__ + "_autodeploy_task"
TASK_STATE = "{}_state".format(TASK_NAME)

RETRY_WAIT_SECS = 2
RETRY_COUNT = 10


class State(IntEnum):
    STARTING = 0
    RUNNING = 1
    FAILED = 2
    STOPPED = 3


async def filter_services(app_config: Dict, stack_file: Path) -> Dict:
    excluded_services = app_config["main"]["docker_stack_recipe"]["excluded_services"]
    excluded_volumes = app_config["main"]["docker_stack_recipe"]["excluded_volumes"]
    with Path(stack_file).open() as fp:
        stack_cfg = yaml.safe_load(fp)
        # remove excluded services
        for service in excluded_services:
            stack_cfg["services"].pop(service, None)
        # remove excluded volumes
        for volume in excluded_volumes:
            stack_cfg["volumes"].pop(volume, None)
        # remove build part, useless in a stack
        for service in stack_cfg["services"].keys():
            stack_cfg["services"][service].pop("build", None)
        return stack_cfg

async def add_parameters(app_config: Dict, stack_cfg: Dict) -> Dict:
    additional_parameters = app_config["main"]["docker_stack_recipe"]["additional_parameters"]
    if not additional_parameters:
        # nothing to add
        return stack_cfg
    for service_key in stack_cfg["services"].keys():
        stack_cfg["services"][service_key].update(additional_parameters)

    return stack_cfg

async def generate_stack_file(app_config: Dict, subtasks: List[SubTask]) -> Path:
    # collect repos informations
    git_repos = {}
    for task in subtasks:
        if isinstance(task, GitUrlWatcher):
            # map the id
            git_repos.update({x.repo_id: x for x in task.watched_repos})

    stack_recipe_cfg = app_config["main"]["docker_stack_recipe"]
    # collect files in one location
    dest_dir = stack_recipe_cfg["workdir"]
    if dest_dir == "temp":
        # create a temp folder
        dest_dir = tempfile.TemporaryDirectory().name
    elif dest_dir in git_repos:
        # we use one of the git repos
        dest_dir = git_repos[dest_dir].directory

    file_groups_to_copy = stack_recipe_cfg["files"]
    for group in file_groups_to_copy:
        git_id = group["id"]
        if not git_id in git_repos:
            raise ConfigurationError(
                "recipe is using an id {} that is not available in the watched git repositories".format(git_id))

        src_dir = git_repos[git_id].directory
        files = group["paths"]
        for src_file in files:
            src = Path(src_dir) / Path(src_file)
            if not src.exists():
                raise ConfigurationError(
                    "recipe from id {} uses file non existing file {}".format(git_id, src_file))
            copy2(src, dest_dir)

    # execute command if available
    if stack_recipe_cfg["command"]:
        cmd = "cd {} && ".format(dest_dir) + stack_recipe_cfg["command"]
        await run_cmd_line(cmd)
    stack_file = Path(dest_dir) / Path(stack_recipe_cfg["stack_file"])
    if not stack_file.exists():
        raise ConfigurationError(
            "The stack file {} does not exist".format(stack_file.name))
    return stack_file


async def update_portainer_stack(app_config: Dict, stack_cfg: Dict):
    log.debug("updateing portainer stack using: %s", stack_cfg)
    portainer_cfg = app_config["main"]["portainer"]
    for config in portainer_cfg:
        url = URL(config["url"])
        bearer_code = await portainer.authenticate(url, config["username"], config["password"])
        current_stack_id = await portainer.get_current_stack_id(url, bearer_code, config["stack_name"])
        if not current_stack_id:
            # stack does not exist
            swarm_id = await portainer.get_swarm_id(url, bearer_code)
            await portainer.post_new_stack(url, bearer_code, swarm_id, config["stack_name"], stack_cfg)
        else:
            log.debug("updating the configuration of the stack...")
            await portainer.update_stack(url, bearer_code, current_stack_id, stack_cfg)


async def create_docker_registries_watch_subtask(app_config: Dict, stack_cfg: Dict) -> SubTask:
    log.debug("creating docker watch subtask")
    docker_subtask = DockerRegistriesWatcher(app_config, stack_cfg)
    await docker_subtask.init()
    return docker_subtask


async def create_git_watch_subtask(app_config: Dict) -> SubTask:
    log.debug("creating git repo watch subtask")
    git_sub_task = GitUrlWatcher(app_config)
    await git_sub_task.init()
    return git_sub_task


async def init_task(app_config: Dict, message: str) -> List[SubTask]:
    log.debug("initialising task")
    subtasks = []
    # start by creating the git watcher/repos
    subtasks.append(await create_git_watch_subtask(app_config))
    # then generate the stack file
    stack_file = await generate_stack_file(app_config, subtasks)
    log.debug("generated stack file in %s", stack_file.name)
    # filter the stack file if needed
    stack_cfg = await filter_services(app_config, stack_file)
    log.debug("filtered stack configuration")
    # add parameter to the stack file if needed
    stack_cfg = await add_parameters(app_config, stack_cfg)
    log.debug("added stack parameters")
    # create the docker repos watchers
    subtasks.append(await create_docker_registries_watch_subtask(app_config, stack_cfg))
    # deploy to portainer
    await update_portainer_stack(app_config, stack_cfg)
    log.debug("updated portainer app")
    # notify
    await notify(app_config, message=message)
    log.debug("task initialised")
    return subtasks


async def check_changes(subtasks: List[SubTask]):
    for task in subtasks:
        changes = await task.check_for_changes()
        if changes:
            log.info("Changes detected with task %s", task.name)
            return True
    return False


@retry(wait=wait_fixed(RETRY_WAIT_SECS),
       stop=stop_after_attempt(RETRY_COUNT),
       before_sleep=before_sleep_log(log, logging.INFO),
       retry=retry_if_exception_type(DependencyNotReadyError))
async def wait_for_dependencies(app_config: Dict):
    log.info("waiting for dependencies to start...")
    # wait for a portainer instance
    portainer_cfg = app_config["main"]["portainer"]
    for config in portainer_cfg:
        url = URL(config["url"])
        try:
            await portainer.authenticate(url, config["username"], config["password"])
            log.info("portainer at %s ready", url)
        except ClientError:
            log.exception("portainer not ready at %s", url)
            raise DependencyNotReadyError(
                "Portainer not ready at {}".format(url))


async def auto_deploy(app: web.Application):
    log.info("start autodeploy task")
    try:
        app[TASK_STATE] = State.STARTING
        app_config = app[APP_CONFIG_KEY]
        log.info("initialising...")
        await wait_for_dependencies(app_config)
        subtasks = await init_task(app_config, message="Stack initialised")
        log.info("initialisation completed")
        app[TASK_STATE] = State.RUNNING
        # loop forever to detect changes
        while True:
            log.info("checking for changes...")
            changes_detected = await check_changes(subtasks)
            if changes_detected:
                log.info("changes detected, redeploying the stack...")
                subtasks = await init_task(app_config, message="Updated stack")
                log.info("stack re-deployed")
            await asyncio.sleep(app_config["main"]["polling_interval"])

    except asyncio.CancelledError:
        log.info("cancelling task...")
        app[TASK_STATE] = State.STOPPED
        raise
    except:
        log.exception("Task closing:")
        app[TASK_STATE] = State.FAILED
        raise
    finally:
        # cleanup the subtasks
        log.info("task completed...")


async def start(app: web.Application):
    app[TASK_NAME] = asyncio.get_event_loop().create_task(auto_deploy(app))


async def cleanup(app: web.Application):
    task = app[TASK_NAME]
    task.cancel()


def setup(app: web.Application):
    app.on_startup.append(start)
    app.on_cleanup.append(cleanup)


__all__ = (
    'setup',
    'State'
)

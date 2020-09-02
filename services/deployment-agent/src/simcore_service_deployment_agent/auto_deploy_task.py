import asyncio
import logging
import tempfile
from pathlib import Path
from shutil import copy2
from typing import Dict, List, Tuple

import yaml
from aiohttp import ClientError, ClientSession, web
from servicelib.application_keys import APP_CONFIG_KEY
from tenacity import (
    before_sleep_log,
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_fixed,
)
from yarl import URL

from . import portainer
from .app_state import State
from .cmd_utils import run_cmd_line
from .docker_registries_watcher import DockerRegistriesWatcher
from .exceptions import ConfigurationError, DependencyNotReadyError
from .git_url_watcher import GitUrlWatcher
from .notifier import notify, notify_state
from .subtask import SubTask

log = logging.getLogger(__name__)
TASK_NAME = __name__ + "_autodeploy_task"
TASK_STATE = "{}_state".format(TASK_NAME)
TASK_SESSION_NAME = __name__ + "session"


RETRY_WAIT_SECS = 2
RETRY_COUNT = 10


async def filter_services(app_config: Dict, stack_file: Path) -> Dict:
    excluded_services = app_config["main"]["docker_stack_recipe"]["excluded_services"]
    excluded_volumes = app_config["main"]["docker_stack_recipe"]["excluded_volumes"]
    log.debug("filtering services and volumes")
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
        log.debug("filtered services: result in %s", stack_cfg)
        return stack_cfg


async def add_parameters(app_config: Dict, stack_cfg: Dict) -> Dict:
    additional_parameters = app_config["main"]["docker_stack_recipe"][
        "additional_parameters"
    ]
    log.debug("adding parameters to stack using %s", additional_parameters)
    for key, value in additional_parameters.items():
        if value and isinstance(value, dict):
            for _, service_params in stack_cfg["services"].items():
                if key in service_params:
                    service_params[key].update(**value)
                else:
                    service_params[key] = value
        elif value and isinstance(value, list):
            for _, service_params in stack_cfg["services"].items():
                if key in service_params:
                    service_params[key].extend(value)
                else:
                    service_params[key] = value
        elif value and isinstance(value, str):
            for _, service_params in stack_cfg["services"].items():
                service_params[key] = value

    return stack_cfg


async def add_prefix_to_services(app_config: Dict, stack_cfg: Dict) -> Dict:
    services_prefix = app_config["main"]["docker_stack_recipe"]["services_prefix"]
    if services_prefix:
        log.debug("adding service prefix %s to all services", services_prefix)
        services = stack_cfg["services"]
        new_services = {}
        for service_name in services.keys():
            new_service_name = f"{services_prefix}_{service_name}"
            new_services[new_service_name] = services[service_name]
        stack_cfg["services"] = new_services
    return stack_cfg


async def generate_stack_file(app_config: Dict, git_task: GitUrlWatcher) -> Path:
    # collect repos informations
    git_repos = {}
    git_repos.update({x.repo_id: x for x in git_task.watched_repos})

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
                "recipe is using an id {} that is not available in the watched git repositories".format(
                    git_id
                )
            )

        src_dir = git_repos[git_id].directory
        files = group["paths"]
        for src_file in files:
            src = Path(src_dir) / Path(src_file)
            if not src.exists():
                raise ConfigurationError(
                    "recipe from id {} uses file non existing file {}".format(
                        git_id, src_file
                    )
                )
            copy2(src, dest_dir)

    # execute command if available
    if stack_recipe_cfg["command"]:
        cmd = "cd {} && ".format(dest_dir) + stack_recipe_cfg["command"]
        await run_cmd_line(cmd)
    stack_file = Path(dest_dir) / Path(stack_recipe_cfg["stack_file"])
    if not stack_file.exists():
        raise ConfigurationError(
            "The stack file {} does not exist".format(stack_file.name)
        )
    return stack_file


async def update_portainer_stack(
    app_config: Dict, app_session: ClientSession, stack_cfg: Dict
):
    log.debug("updateing portainer stack using: %s", stack_cfg)
    portainer_cfg = app_config["main"]["portainer"]
    for config in portainer_cfg:
        url = URL(config["url"])
        bearer_code = await portainer.authenticate(
            url, app_session, config["username"], config["password"]
        )
        current_stack_id = await portainer.get_current_stack_id(
            url, app_session, bearer_code, config["stack_name"]
        )
        if not current_stack_id:
            # stack does not exist
            swarm_id = await portainer.get_swarm_id(
                url, app_session, bearer_code, config["endpoint_id"]
            )
            await portainer.post_new_stack(
                url,
                app_session,
                bearer_code,
                swarm_id,
                config["endpoint_id"],
                config["stack_name"],
                stack_cfg,
            )
        else:
            log.debug("updating the configuration of the stack...")
            await portainer.update_stack(
                url,
                app_session,
                bearer_code,
                current_stack_id,
                config["endpoint_id"],
                stack_cfg,
            )


async def create_docker_registries_watch_subtask(
    app_config: Dict, stack_cfg: Dict
) -> DockerRegistriesWatcher:
    log.debug("creating docker watch subtask")
    docker_subtask = DockerRegistriesWatcher(app_config, stack_cfg)
    await docker_subtask.init()
    return docker_subtask


async def create_git_watch_subtask(app_config: Dict) -> Tuple[GitUrlWatcher, Dict]:
    log.debug("creating git repo watch subtask")
    git_sub_task = GitUrlWatcher(app_config)
    descriptions = await git_sub_task.init()
    return (git_sub_task, descriptions)


async def create_stack(git_task: GitUrlWatcher, app_config: Dict) -> Dict:
    # generate the stack file
    stack_file = await generate_stack_file(app_config, git_task)
    log.debug("generated stack file in %s", stack_file.name)
    # filter the stack file if needed
    stack_cfg = await filter_services(app_config, stack_file)
    log.debug("filtered stack configuration")
    # add parameter to the stack file if needed
    stack_cfg = await add_parameters(app_config, stack_cfg)
    log.debug("new stack config is\n%s", stack_file)
    # change services names to avoid conflicts in common networks
    stack_cfg = await add_prefix_to_services(app_config, stack_cfg)
    log.debug("final stack config is: %s", stack_cfg)

    return stack_cfg


async def check_changes(subtasks: List[SubTask]) -> Dict:
    changes = {}
    for task in subtasks:
        changes.update(await task.check_for_changes())
    return changes


@retry(
    wait=wait_fixed(RETRY_WAIT_SECS),
    stop=stop_after_attempt(RETRY_COUNT),
    before_sleep=before_sleep_log(log, logging.INFO),
    retry=retry_if_exception_type(DependencyNotReadyError),
)
async def wait_for_dependencies(app_config: Dict, app_session: ClientSession):
    log.info("waiting for dependencies to start...")
    # wait for a portainer instance
    portainer_cfg = app_config["main"]["portainer"]
    for config in portainer_cfg:
        url = URL(config["url"])
        try:
            await portainer.authenticate(
                url, app_session, config["username"], config["password"]
            )
            log.info("portainer at %s ready", url)
        except ClientError:
            log.exception("portainer not ready at %s", url)
            raise DependencyNotReadyError("Portainer not ready at {}".format(url))


async def _init_deploy(
    app: web.Application,
) -> Tuple[GitUrlWatcher, DockerRegistriesWatcher]:
    try:
        log.info("initialising...")
        # get configs
        app[TASK_STATE] = State.STARTING
        app_config = app[APP_CONFIG_KEY]
        app_session = app[TASK_SESSION_NAME]
        # wait for portainer to be available
        await wait_for_dependencies(app_config, app_session)
        # create initial stack
        git_task, descriptions = await create_git_watch_subtask(app_config)
        stack_cfg = await create_stack(git_task, app_config)
        docker_task = await create_docker_registries_watch_subtask(
            app_config, stack_cfg
        )
        # deploy stack to swarm
        await update_portainer_stack(app_config, app_session, stack_cfg)
        # notifications
        await notify(
            app_config,
            app_session,
            message=f"Stack initialised with:\n{list(descriptions.values())}",
        )
        main_repo = app_config["main"]["docker_stack_recipe"]["workdir"]
        await notify_state(
            app_config,
            app_session,
            state=app[TASK_STATE],
            message=descriptions[main_repo] if main_repo in descriptions else "",
        )
        log.info("initialisation completed")
        return (git_task, docker_task)
    except asyncio.CancelledError:
        log.info("cancelling task...")
        app[TASK_STATE] = State.STOPPED
        raise
    except Exception:
        log.exception("Task closing:")
        app[TASK_STATE] = State.FAILED
        raise
    finally:
        # cleanup the subtasks
        log.info("task completed...")


async def _deploy(
    app: web.Application, git_task: GitUrlWatcher, docker_task: DockerRegistriesWatcher
) -> DockerRegistriesWatcher:
    app_config = app[APP_CONFIG_KEY]
    app_session = app[TASK_SESSION_NAME]
    log.info("checking for changes...")
    changes = await check_changes([git_task, docker_task])
    if not changes:
        return docker_task

    stack_cfg = await create_stack(git_task, app_config)
    docker_task = await create_docker_registries_watch_subtask(app_config, stack_cfg)

    # deploy stack to swarm
    log.info("redeploying the stack...")
    await update_portainer_stack(app_config, app_session, stack_cfg)
    log.info("sending notifications...")
    changes_as_texts = [f"{key}:{value}" for key, value in changes.items()]
    await notify(app_config, app_session, message=f"Updated stack\n{changes_as_texts}")
    main_repo = app_config["main"]["docker_stack_recipe"]["workdir"]
    if main_repo in changes:
        await notify_state(
            app_config, app_session, state=app[TASK_STATE], message=changes[main_repo]
        )
    log.info("stack re-deployed")
    return docker_task


async def auto_deploy(app: web.Application):
    log.info("start autodeploy task")
    app_config = app[APP_CONFIG_KEY]
    app_session = app[TASK_SESSION_NAME]
    # init
    git_task, docker_task = await _init_deploy(app)
    # loop forever to detect changes
    while True:
        try:
            app[TASK_STATE] = State.RUNNING
            docker_task = await _deploy(app, git_task, docker_task)
            await asyncio.sleep(app_config["main"]["polling_interval"])
        except asyncio.CancelledError:
            log.info("cancelling task...")
            app[TASK_STATE] = State.STOPPED
            raise
        except Exception as exc:  # pylint: disable=broad-except
            # some unknown error happened, let's wait 5 min and restart
            log.exception("Task error:")
            if app[TASK_STATE] != State.PAUSED:
                app[TASK_STATE] = State.PAUSED
                await notify_state(
                    app_config, app_session, state=app[TASK_STATE], message=str(exc)
                )
            await asyncio.sleep(300)
        finally:
            # cleanup the subtasks
            log.info("task completed...")


def setup(app: web.Application):
    app.cleanup_ctx.append(persistent_session)
    app.cleanup_ctx.append(background_task)


async def background_task(app: web.Application):
    app[TASK_STATE] = State.STARTING
    app[TASK_NAME] = asyncio.get_event_loop().create_task(auto_deploy(app))
    yield
    task = app[TASK_NAME]
    task.cancel()


async def persistent_session(app):
    app[TASK_SESSION_NAME] = session = ClientSession()
    yield
    await session.close()


__all__ = "setup"

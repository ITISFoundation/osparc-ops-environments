import logging
import re
import shutil
import tempfile
from pathlib import Path
from typing import Dict, List, Tuple

import attr
from tenacity import after_log, retry, stop_after_attempt, wait_random
from yarl import URL

from .cmd_utils import run_cmd_line
from .subtask import SubTask

log = logging.getLogger(__name__)

NUMBER_OF_ATTEMPS = 5
MAX_TIME_TO_WAIT_S = 10


async def _git_clone_repo(repository: URL, directory: Path, branch: str, username: str = None, password: str = None):
    cmd = "git clone -n {repository} --depth 1 {directory} --single-branch --branch {branch}".format(
        repository=URL(repository).with_user(username).with_password(password), directory=directory, branch=branch)
    await run_cmd_line(cmd)


async def _git_checkout_files(directory: Path, paths: List[Path], tag: str = "HEAD"):
    cmd = "cd {directory} && git checkout {tag} {path}".format(directory=directory,
                                                            tag=tag, path=" ".join(paths))
    await run_cmd_line(cmd)


async def _git_checkout_file(directory: Path, file_path: Path, tag: str = "HEAD"):
    await _git_checkout_files(directory, [file_path], tag)

async def _git_checkout_repo(directory: Path, tag: str = "HEAD"):
    cmd = "cd {directory} && git checkout {tag}".format(directory=directory, tag=tag)
    await run_cmd_line(cmd)


async def _git_pull_files(directory: Path, paths: List[Path]):
    cmd = "cd {directory} && git checkout FETCH_HEAD {path}".format(directory=directory,
                                                                    path=" ".join(paths))
    await run_cmd_line(cmd)


async def _git_pull(directory: Path):
    cmd = "cd {directory} && git pull".format(directory=directory)
    await run_cmd_line(cmd)

async def _git_fetch(directory: Path):
    cmd = "cd {directory} && git fetch --prune --tags".format(directory=directory)
    await run_cmd_line(cmd)

async def _git_get_latest_matching_tag(directory: Path, regexp: str) -> List[str]:
    cmd = "cd {directory} && git --no-pager describe --tags --always `git rev-list --tags`".format(directory=directory)
    all_tags = await run_cmd_line(cmd)
    if not all_tags:
        return []
    list_tags = all_tags.split("\n")
    reg_object = re.compile(regexp)
    for tag in list_tags:
        if reg_object.fullmatch(tag):
            return tag
    return ""

async def _git_get_current_tag(directory: Path, regexp: str) -> str:
    cmd = "cd {directory} && git --no-pager describe --tags --always".format(directory=directory)
    current_tag = await run_cmd_line(cmd)
    match = re.fullmatch(regexp, current_tag)
    if match:
        return current_tag
    return ""

async def _git_diff_filenames(directory: Path) -> str:
    cmd = "cd {directory} && git --no-pager diff --name-only FETCH_HEAD".format(
        directory=directory)
    modified_files = await run_cmd_line(cmd)
    return modified_files

async def _git_diff_filenames_tags(directory: Path, tag1: str, tag2: str) -> str:
    cmd = "cd {directory} && git --no-pager diff --name-only {tag1} {tag2}".format(
        directory=directory, tag1=tag1, tag2=tag2)
    modified_files = await run_cmd_line(cmd)
    return modified_files

async def _git_get_logs(directory: Path, branch1: str, branch2: str) -> str:
    cmd = "cd {directory} && git --no-pager log --oneline {branch1}..origin/{branch2}".format(
        directory=directory, branch1=branch1, branch2=branch2)
    logs = await run_cmd_line(cmd)
    return logs

async def _git_get_logs_tags(directory: Path, tag1: str, tag2: str) -> str:
    cmd = "cd {directory} && git --no-pager log --oneline {tag1}{tag2}".format(
        directory=directory,
        tag1=tag1,
        tag2=".." + tag2 if tag1 else tag2
        )
    logs = await run_cmd_line(cmd)
    return logs

watched_repos = list()


@attr.s(auto_attribs=True)
class GitRepo:  # pylint: disable=too-many-instance-attributes, too-many-arguments
    repo_id: str
    repo_url: URL
    branch: str
    tags: str
    username: str
    password: str
    paths: List[Path]
    pull_only_files: bool
    directory: str = ""


async def _init_repositories(repos: List[GitRepo]):
    for repo in repos:
        repo.directory = tempfile.TemporaryDirectory().name
        await _git_clone_repo(repo.repo_url, repo.directory, repo.branch, repo.username, repo.password)
        if repo.pull_only_files:
            await _git_checkout_files(repo.directory, repo.paths)
        else:
            await _git_checkout_repo(repo.directory)


async def _check_repositories(repos: List[GitRepo]) -> Tuple[bool, str]:
    change_detected = False
    changes = ""
    for repo in repos:
        log.debug("checking repo: %s...", repo.repo_url)
        assert repo.directory
        await _git_fetch(repo.directory)

        if repo.tags:
            current_tag = await _git_get_current_tag(repo.directory, repo.tags)
            latest_tag = await _git_get_latest_matching_tag(repo.directory, repo.tags)
            if current_tag != latest_tag:
                log.info("New tag detected: %s, checking out...", latest_tag)
                modified_files = await _git_diff_filenames_tags(repo.directory, current_tag, latest_tag)
                log.debug("%s tag modified files: %s", latest_tag, modified_files)
                changes = await _git_get_logs_tags(repo.directory, current_tag, latest_tag)
                log.debug("%s tag changes: %s", latest_tag, changes)
                if repo.pull_only_files:
                    await _git_checkout_files(latest_tag, repo.paths)
                else:
                    await _git_checkout_repo(repo.directory, latest_tag)
                log.info("New tag %s  checked out", latest_tag)
                # check if a watched file has changed
                if modified_files:
                    common_files = set(modified_files.split()
                                    ).intersection(set(repo.paths))
                    if common_files:
                        log.info("File %s changed!!", common_files)
                        change_detected = True
        else:
            modified_files = await _git_diff_filenames(repo.directory)
            if not modified_files:
                # no modifications
                continue
            # get the logs
            changes = await _git_get_logs(repo.directory, repo.branch, repo.branch)
            if repo.pull_only_files:
                await _git_pull_files(repo.directory, repo.paths)
            else:
                await _git_pull(repo.directory)
            # check if a watched file has changed
            common_files = set(modified_files.split()
                            ).intersection(set(repo.paths))
            if common_files:
                log.info("File %s changed!!", common_files)
                change_detected = True

    return (change_detected, changes)


async def _delete_repositories(repos: List[GitRepo]):
    for repo in repos:
        shutil.rmtree(repo.directory, ignore_errors=True)


class GitUrlWatcher(SubTask):
    def __init__(self, app_config: Dict):
        super().__init__(name="git repo watcher")
        self.watched_repos = []
        watched_compose_files_config = app_config["main"]["watched_git_repositories"]
        for config in watched_compose_files_config:
            repo = GitRepo(repo_id=config["id"],
                           repo_url=config["url"],
                           branch=config["branch"],
                           tags=config["tags"],
                           pull_only_files=config["pull_only_files"],
                           username=config["username"],
                           password=config["password"],
                           paths=config["paths"])
            self.watched_repos.append(repo)

    async def init(self):
        await _init_repositories(self.watched_repos)

    @retry(reraise=True, stop=stop_after_attempt(NUMBER_OF_ATTEMPS), wait=wait_random(min=1, max=MAX_TIME_TO_WAIT_S), after=after_log(log, logging.DEBUG))
    async def check_for_changes(self) -> Tuple[bool, str]:
        result = await _check_repositories(self.watched_repos)
        return result

    async def cleanup(self):
        await _delete_repositories(self.watched_repos)


__all__ = (
    'GitUrlWatcher'
)

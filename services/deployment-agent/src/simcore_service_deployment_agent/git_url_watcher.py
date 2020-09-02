import logging
import re
import shutil
import tempfile
from pathlib import Path
from typing import Dict, List, Optional

import attr
from tenacity import after_log, retry, stop_after_attempt, wait_random
from yarl import URL

from .cmd_utils import run_cmd_line
from .exceptions import ConfigurationError
from .subtask import SubTask

log = logging.getLogger(__name__)

NUMBER_OF_ATTEMPS = 5
MAX_TIME_TO_WAIT_S = 10


async def _git_clone_repo(
    repository: URL,
    directory: Path,
    branch: str,
    username: str = None,
    password: str = None,
):
    cmd = f"git clone -n {URL(repository).with_user(username).with_password(password)} --depth 1 {directory} --single-branch --branch {branch}"
    await run_cmd_line(cmd)


async def _git_get_current_sha(directory: Path) -> str:
    cmd = f"cd {directory} && git rev-parse --short HEAD"
    sha = await run_cmd_line(cmd)
    return sha.strip("\n")


async def _git_clean_repo(directory: Path):
    cmd = f"cd {directory} && git clean -dxf"
    await run_cmd_line(cmd)


async def _git_checkout_files(directory: Path, paths: List[Path], tag: str = None):
    if not tag:
        tag = "HEAD"
    cmd = f"cd {directory} && git checkout {tag} {' '.join(paths)}"
    await run_cmd_line(cmd)


async def _git_checkout_repo(directory: Path, tag: str = None):
    await _git_checkout_files(directory, [], tag)


async def _git_pull_files(directory: Path, paths: List[Path]):
    cmd = f"cd {directory} && git checkout FETCH_HEAD {' '.join(paths)}"
    await run_cmd_line(cmd)


async def _git_pull(directory: Path):
    cmd = f"cd {directory} && git pull"
    await run_cmd_line(cmd)


async def _git_fetch(directory: Path):
    cmd = f"cd {directory} && git fetch --prune --tags"
    await run_cmd_line(cmd)


async def _git_get_latest_matching_tag(directory: Path, regexp: str) -> Optional[str]:
    cmd = f'cd {directory} && git tag --list --sort=committerdate | grep --extended-regexp --only-matching "{regexp}" | sort --reverse'
    all_tags = await run_cmd_line(cmd)
    if not all_tags:
        return
    list_tags = all_tags.split("\n")
    reg_object = re.compile(regexp)
    for tag in list_tags:
        if reg_object.fullmatch(tag):
            return tag
    return


async def _git_get_current_matching_tag(directory: Path, regexp: str) -> List[str]:
    # NOTE: there might be several tags on the same commit
    reg = regexp
    if regexp.startswith("^"):
        reg = regexp[1:]
    cmd = f'cd {directory} && git show-ref --tags --dereference | grep --perl-regexp --only-matching "(?<=$(git rev-parse HEAD) refs/tags/){reg}"'
    all_tags = await run_cmd_line(cmd)
    if not all_tags:
        return []
    return all_tags.split("\n")


async def _git_diff_filenames(directory: Path) -> Optional[str]:
    cmd = f"cd {directory} && git --no-pager diff --name-only FETCH_HEAD"
    modified_files = await run_cmd_line(cmd)
    return modified_files


async def _git_get_logs(directory: Path, branch1: str, branch2: str) -> Optional[str]:
    cmd = f"cd {directory} && git --no-pager log --oneline {branch1}..origin/{branch2}"
    logs = await run_cmd_line(cmd)
    return logs


async def _git_get_logs_tags(directory: Path, tag1: str, tag2: str) -> Optional[str]:
    cmd = f"cd {directory} && git --no-pager log --oneline {tag1}{'..' + tag2 if tag1 else tag2}"
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


async def _checkout_repository(repo: GitRepo, tag: str = None):
    if repo.pull_only_files:
        await _git_checkout_files(repo.directory, repo.paths, tag)
    else:
        await _git_checkout_repo(repo.directory, tag)


async def _update_repository(repo: GitRepo):
    if repo.pull_only_files:
        await _git_pull_files(repo.directory, repo.paths)
    else:
        await _git_pull(repo.directory)


async def _init_repositories(repos: List[GitRepo]) -> Dict:
    description = {}
    for repo in repos:
        repo.directory = tempfile.TemporaryDirectory().name
        log.debug("cloning %s in %s...", repo.repo_id, repo.directory)
        await _git_clone_repo(
            repo.repo_url, repo.directory, repo.branch, repo.username, repo.password
        )
        await _git_fetch(repo.directory)
        latest_tag = (
            await _git_get_latest_matching_tag(repo.directory, repo.tags)
            if repo.tags
            else None
        )
        log.debug(
            "latest tag found for %s is %s, now checking out...",
            repo.repo_id,
            latest_tag,
        )
        if not latest_tag and repo.tags:
            raise ConfigurationError(
                msg=f"no tags found in {repo.repo_url}:{repo.branch} that follows defined tags pattern {repo.tags}: {latest_tag}"
            )

        await _checkout_repository(repo, latest_tag)
        log.info("repository %s checked out on %s", repo, latest_tag)
        sha = await _git_get_current_sha(repo.directory)
        log.debug("sha for %s is %s", repo.repo_id, sha)
        description[repo.repo_id] = (
            f"{repo.repo_id}:{repo.branch}:{latest_tag}:{sha}"
            if latest_tag
            else f"{repo.repo_id}:{repo.branch}:{sha}"
        )
    return description


async def _update_repo_using_tags(repo: GitRepo) -> Optional[str]:
    log.debug("checking %s using tags", repo.repo_id)
    # check if current tag is the latest and greatest
    list_current_tags = await _git_get_current_matching_tag(repo.directory, repo.tags)
    latest_tag = await _git_get_latest_matching_tag(repo.directory, repo.tags)
    # there should always be a tag
    if not latest_tag:
        raise ConfigurationError(
            msg=f"no tags found in {repo.repo_id} that follows defined tags pattern {repo.tags}"
        )

    log.debug(
        "following tags found for %s, current: %s, latest: %s",
        repo.repo_id,
        list_current_tags,
        latest_tag,
    )
    if latest_tag in list_current_tags:
        log.debug("no change detected")
        return
    log.info("New tag detected: %s", latest_tag)

    # get modifications
    logged_changes = await _git_get_logs_tags(
        repo.directory, list_current_tags[0], latest_tag
    )
    log.debug("%s tag changes: %s", latest_tag, logged_changes)

    # checkout
    await _checkout_repository(repo, latest_tag)
    log.info("New tag %s  checked out", latest_tag)

    # if the tag changed, an update is needed even if no files were changed
    sha = await _git_get_current_sha(repo.directory)
    return f"{repo.repo_id}:{repo.branch}:{latest_tag}:{sha}"


async def _update_repo_using_branch_head(repo: GitRepo) -> Optional[str]:
    modified_files = await _git_diff_filenames(repo.directory)
    if not modified_files:
        # no modifications
        return
    # get the logs
    logged_changes = await _git_get_logs(repo.directory, repo.branch, repo.branch)
    log.debug("Changelog:\n%s", logged_changes)
    await _update_repository(repo)
    # check if a watched file has changed
    common_files = set(modified_files.split()).intersection(set(repo.paths))
    if not common_files:
        # no change affected the watched files
        return

    log.info("File %s changed!!", common_files)
    sha = await _git_get_current_sha(repo.directory)
    return f"{repo.repo_id}:{repo.branch}:{sha}"


async def _check_repositories(repos: List[GitRepo]) -> Dict:
    changes = {}
    for repo in repos:
        log.debug("checking repo: %s...", repo.repo_url)
        assert repo.directory
        await _git_fetch(repo.directory)
        await _git_clean_repo(repo.directory)

        repo_changes = (
            await _update_repo_using_tags(repo)
            if repo.tags
            else await _update_repo_using_branch_head(repo)
        )
        if repo_changes:
            changes[repo.repo_id] = repo_changes

    return changes


async def _delete_repositories(repos: List[GitRepo]):
    for repo in repos:
        shutil.rmtree(repo.directory, ignore_errors=True)


class GitUrlWatcher(SubTask):
    def __init__(self, app_config: Dict):
        super().__init__(name="git repo watcher")
        self.watched_repos = []
        watched_compose_files_config = app_config["main"]["watched_git_repositories"]
        for config in watched_compose_files_config:
            repo = GitRepo(
                repo_id=config["id"],
                repo_url=config["url"],
                branch=config["branch"],
                tags=config["tags"],
                pull_only_files=config["pull_only_files"],
                username=config["username"],
                password=config["password"],
                paths=config["paths"],
            )
            self.watched_repos.append(repo)

    async def init(self) -> Dict:
        description = await _init_repositories(self.watched_repos)
        return description

    @retry(
        reraise=True,
        stop=stop_after_attempt(NUMBER_OF_ATTEMPS),
        wait=wait_random(min=1, max=MAX_TIME_TO_WAIT_S),
        after=after_log(log, logging.DEBUG),
    )
    async def check_for_changes(self) -> Dict:
        return await _check_repositories(self.watched_repos)

    async def cleanup(self):
        await _delete_repositories(self.watched_repos)


__all__ = "GitUrlWatcher"

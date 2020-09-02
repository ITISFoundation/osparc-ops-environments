# pylint:disable=wildcard-import
# pylint:disable=unused-import
# pylint:disable=unused-variable
# pylint:disable=unused-argument
# pylint:disable=redefined-outer-name
# pylint:disable=bare-except

from pathlib import Path
from asyncio import Future
import pytest
import yaml

from simcore_service_deployment_agent import git_url_watcher


def _list_valid_configs():
    return [
        "valid_git_config.yaml",
        "valid_git_config_path.yaml",
        "valid_git_config_staging.yaml",
        "valid_git_config_staging_tags.yaml",
    ]


@pytest.fixture(scope="session", params=_list_valid_configs())
def valid_git_config(here, request):
    with Path(here / "mocks" / request.param).open() as fp:
        return yaml.safe_load(fp)


async def test_watcher_workflow(loop, valid_git_config, mocker):

    mock_general = mocker.patch(
        "simcore_service_deployment_agent.git_url_watcher.run_cmd_line",
        return_value=Future(),
    )
    mock_general.return_value.set_result("")
    mock_latest_tag = mocker.patch.object(
        git_url_watcher, "_git_get_latest_matching_tag", return_value=Future()
    )
    TAG = "1.2.3"
    mock_latest_tag.return_value.set_result(TAG)
    mock_latest_tag = mocker.patch.object(
        git_url_watcher, "_git_get_current_matching_tag", return_value=Future()
    )
    mock_latest_tag.return_value.set_result([TAG])
    mock_sha = mocker.patch.object(
        git_url_watcher, "_git_get_current_sha", return_value=Future()
    )
    SHA = "asdhjfs"
    mock_sha.return_value.set_result(SHA)
    git_watcher = git_url_watcher.GitUrlWatcher(valid_git_config)

    with pytest.raises(AssertionError):
        await git_watcher.check_for_changes()
    mock_general.assert_not_called()

    REPO_ID = valid_git_config["main"]["watched_git_repositories"][0]["id"]
    BRANCH = valid_git_config["main"]["watched_git_repositories"][0]["branch"]
    TAGS = (
        valid_git_config["main"]["watched_git_repositories"][0]["tags"]
        if "tags" in valid_git_config["main"]["watched_git_repositories"][0]
        else None
    )
    description = (
        f"{REPO_ID}:{BRANCH}:{TAG}:{SHA}" if TAGS else f"{REPO_ID}:{BRANCH}:{SHA}"
    )

    assert await git_watcher.init() == {REPO_ID: description}
    assert not await git_watcher.check_for_changes()

    mock_changed_files = mocker.patch.object(
        git_url_watcher, "_git_diff_filenames", return_value=Future()
    )
    CHANGED_FILE = valid_git_config["main"]["watched_git_repositories"][0]["paths"][0]
    mock_changed_files.return_value.set_result(CHANGED_FILE)
    NEW_TAG = "2.3.4"
    mock_latest_tag.return_value = Future()
    mock_latest_tag.return_value.set_result(NEW_TAG)
    assert await git_watcher.check_for_changes() == {REPO_ID: description}

    try:
        await git_watcher.cleanup()
    except:
        pytest.fail("Unexpected error deleting repos...")

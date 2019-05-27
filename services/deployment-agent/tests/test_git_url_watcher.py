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
        "valid_git_config_path.yaml"
    ]

@pytest.fixture(scope="session", params=_list_valid_configs())
def valid_git_config(here, request):
    with Path(here / "mocks" / request.param).open() as fp:
        return yaml.safe_load(fp)

async def test_watcher_workflow(loop, valid_git_config, mocker):
    mock = mocker.patch(
        "simcore_service_deployment_agent.git_url_watcher.run_cmd_line", return_value=Future())
    mock.return_value.set_result("")
    git_watcher = git_url_watcher.GitUrlWatcher(valid_git_config)

    with pytest.raises(AssertionError):
        await git_watcher.check_for_changes()
    mock.assert_not_called()

    try:
        await git_watcher.init()
    except:
        pytest.fail("Unexpected error cloning repos...")
    mock.assert_called()

    assert await git_watcher.check_for_changes() == (False, "")

    mock_changed_files = mocker.patch(
        "simcore_service_deployment_agent.git_url_watcher.run_cmd_line", return_value=Future())
    mock_changed_files.return_value.set_result("Makefile")
    assert await git_watcher.check_for_changes() == (True, "Makefile")

    try:
        await git_watcher.cleanup()
    except:
        pytest.fail("Unexpected error deleting repos...")

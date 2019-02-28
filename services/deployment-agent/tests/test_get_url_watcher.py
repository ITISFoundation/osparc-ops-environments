# pylint:disable=wildcard-import
# pylint:disable=unused-import
# pylint:disable=unused-variable
# pylint:disable=unused-argument
# pylint:disable=redefined-outer-name
# pylint:disable=bare-except

from pathlib import Path

import pytest
import yaml

from simcore_service_deployment_agent import git_url_watcher


@pytest.fixture
def valid_git_config(here):
    with Path(here / "mocks" / "valid_git_config.yaml").open() as fp:
        return yaml.safe_load(fp)


def test_watcher_workflow(async_subprocess_compatible_loop, valid_git_config):
    git_watcher = git_url_watcher.GitUrlWatcher(valid_git_config)

    with pytest.raises(AssertionError):
        async_subprocess_compatible_loop.run_until_complete(
            git_watcher.check_for_changes())

    try:
        async_subprocess_compatible_loop.run_until_complete(git_watcher.init())
    except:
        pytest.fail("Unexpected error cloning repos...")

    assert async_subprocess_compatible_loop.run_until_complete(
        git_watcher.check_for_changes()) == False

    try:
        async_subprocess_compatible_loop.run_until_complete(
            git_watcher.cleanup())
    except:
        pytest.fail("Unexpected error deleting repos...")

# pylint:disable=wildcard-import
# pylint:disable=unused-import
# pylint:disable=unused-variable
# pylint:disable=unused-argument
# pylint:disable=redefined-outer-name
# pylint:disable=bare-except

from asyncio import Future
from pathlib import Path

import pytest
import yaml
from aiohttp import ClientError, web
from servicelib.application_keys import APP_CONFIG_KEY
from tenacity import RetryError
from yarl import URL

from simcore_service_deployment_agent import auto_deploy_task


@pytest.fixture
async def fake_app(test_config):
    app = web.Application()
    app[APP_CONFIG_KEY] = test_config
    yield app


@pytest.fixture
def valid_portainer_config(here):
    with Path(here / "mocks" / "valid_portainer_config.yaml").open() as fp:
        return yaml.safe_load(fp)


async def test_wait_for_dependencies(loop, valid_portainer_config, mocker):
    mock = mocker.patch(
        "simcore_service_deployment_agent.auto_deploy_task.portainer.authenticate", return_value=Future())
    mock.return_value.set_result("")

    await auto_deploy_task.wait_for_dependencies(valid_portainer_config)

    calls = []
    for portainer_cfg in valid_portainer_config["main"]["portainer"]:
        calls.append(mocker.call(
            URL(portainer_cfg["url"]), portainer_cfg["username"], portainer_cfg["password"]))

    mock.assert_has_calls(calls)

    mock = mocker.patch(
        "simcore_service_deployment_agent.auto_deploy_task.portainer.authenticate", side_effect=ClientError)
    with pytest.raises(RetryError):
        await auto_deploy_task.wait_for_dependencies(valid_portainer_config)
    calls = []

    mock.assert_called()
    assert mock.call_count == auto_deploy_task.RETRY_COUNT


async def test_filter_services(loop, valid_config, valid_docker_stack_file):
    stack_cfg = await auto_deploy_task.filter_services(valid_config, valid_docker_stack_file)
    assert "app" not in stack_cfg["services"]
    assert "some_volume" not in stack_cfg["volumes"]
    assert "build" not in stack_cfg["services"]["anotherapp"]


async def test_setup_task(loop, fake_app):
    try:
        auto_deploy_task.setup(fake_app)
    except:
        pytest.fail("Unexpected error")

    try:
        await auto_deploy_task.start(fake_app)
        assert auto_deploy_task.TASK_NAME in fake_app
        # await fake_app[auto_deploy_task.TASK_NAME] (infinite needs a mock that fails after a while)
        await auto_deploy_task.cleanup(fake_app)
    except:
        pytest.fail("Unexpected error")

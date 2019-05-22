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

async def test_add_parameters(loop, valid_config, valid_docker_stack):
    stack_cfg = await auto_deploy_task.add_parameters(valid_config, valid_docker_stack)
    assert "extra_hosts" in stack_cfg["services"]["app"]
    hosts = stack_cfg["services"]["app"]["extra_hosts"]
    assert "original_host:243.23.23.44" in hosts
    assert "some_test_host:123.43.23.44" in hosts
    assert "another_test_host:332.4.234.12" in hosts

    assert "environment" in stack_cfg["services"]["app"]
    envs = stack_cfg["services"]["app"]["environment"]
    assert "ORIGINAL_ENV" in envs
    assert envs["ORIGINAL_ENV"] == "the original env"
    assert "YET_ANOTHER_ENV" in envs
    assert envs["YET_ANOTHER_ENV"] == "this one is replaced"
    assert "TEST_ENV" in envs
    assert envs["TEST_ENV"] == "some test"
    assert "ANOTHER_TEST_ENV" in envs
    assert envs["ANOTHER_TEST_ENV"] == "some other test"

    assert "extra_hosts" in stack_cfg["services"]["anotherapp"]
    hosts = stack_cfg["services"]["anotherapp"]["extra_hosts"]
    assert "some_test_host:123.43.23.44" in hosts
    assert "another_test_host:332.4.234.12" in hosts
    assert "environment" in stack_cfg["services"]["app"]
    envs = stack_cfg["services"]["app"]["environment"]
    assert "TEST_ENV" in envs
    assert envs["TEST_ENV"] == "some test"
    assert "ANOTHER_TEST_ENV" in envs
    assert envs["ANOTHER_TEST_ENV"] == "some other test"

    assert "image" in stack_cfg["services"]["app"]
    assert "testimage" in stack_cfg["services"]["app"]["image"]
    assert "image" in stack_cfg["services"]["anotherapp"]
    assert "testimage" in stack_cfg["services"]["anotherapp"]["image"]


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

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

from simcore_service_deployment_agent import docker_registries_watcher


@pytest.fixture
def valid_docker_config(here):
    with Path(here / "mocks" / "valid_docker_config.yaml").open() as fp:
        return yaml.safe_load(fp)


def _assert_docker_client_calls(mocked_docker_client, mocker, registry_config, docker_stack):
    mocked_docker_client.assert_has_calls(
        [
            mocker.call.from_env(),
            mocker.call.from_env().ping(),
            mocker.call.from_env().login(**{
                "password": registry_config["password"],
                "registry": registry_config["url"],
                "username": registry_config["username"]
            }),
            mocker.call.from_env().images.get_registry_data(
                docker_stack["services"]["app"]["image"])
        ])


async def test_watcher_workflow(loop, valid_docker_config, valid_docker_stack, mocker):
    docker_registries_watcher.NUMBER_OF_ATTEMPS = 1
    mocked_docker_client = mocker.patch(
        "simcore_service_deployment_agent.docker_registries_watcher.docker",
        **{"from_env.return_value.images.get_registry_data.return_value.attrs": {"Descriptor":"somesignature"},
           "errors.APIError": BaseException})
    docker_watcher = docker_registries_watcher.DockerRegistriesWatcher(
        valid_docker_config, valid_docker_stack)
    registry_config = valid_docker_config["main"]["docker_private_registries"][0]
    with pytest.raises(KeyError):
        await docker_watcher.check_for_changes()
    _assert_docker_client_calls(
        mocked_docker_client, mocker, registry_config, valid_docker_stack)

    try:
        await docker_watcher.init()
    except:
        pytest.fail("Unexpected error initializing docker watcher...")
    _assert_docker_client_calls(
        mocked_docker_client, mocker, registry_config, valid_docker_stack)

    try:
        assert not await docker_watcher.check_for_changes()
    except:
        pytest.fail("Unexpected error checking for changes docker watcher...")
    _assert_docker_client_calls(
        mocked_docker_client, mocker, registry_config, valid_docker_stack)

    # generate a change
    mocked_docker_client.configure_mock(**{
        "from_env.return_value.images.get_registry_data.return_value.attrs": {"Descriptor":"someothersignature"}
    })
    try:
        assert await docker_watcher.check_for_changes() == \
            {
                'jenkins:latest': 'image signature changed',
                'ubuntu': 'image signature changed',
            }
    except:
        pytest.fail("Unexpected error checking for changes docker watcher...")

    try:
        await docker_watcher.cleanup()
    except:
        pytest.fail("Unexpected error cleaning up repos...")

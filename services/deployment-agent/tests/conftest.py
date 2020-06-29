# pylint: disable=unused-argument
# pylint: disable=unused-import
# pylint: disable=bare-except
# pylint:disable=redefined-outer-name

import asyncio
import platform
import sys
from pathlib import Path

import pytest
import yaml

import simcore_service_deployment_agent


@pytest.fixture(scope='session')
def here():
    return Path(sys.argv[0] if __name__ == "__main__" else __file__).resolve().parent


@pytest.fixture(scope='session')
def package_dir(here):
    dirpath = Path(simcore_service_deployment_agent.__file__).resolve().parent
    assert dirpath.exists()
    return dirpath


@pytest.fixture(scope='session')
def osparc_simcore_root_dir(here):
    root_dir = here.parent.parent.parent.resolve()
    assert root_dir.exists(), "Is this service within osparc-simcore repo?"
    assert any(root_dir.glob("services/deployment-agent")
               ), "%s not look like rootdir" % root_dir
    return root_dir


@pytest.fixture(scope='session')
def api_specs_dir(osparc_simcore_root_dir):
    specs_dir = osparc_simcore_root_dir / "services" / "deployment-agent" / \
        "src" / "simcore_service_deployment_agent" / "oas3"
    assert specs_dir.exists()
    return specs_dir


@pytest.fixture
def test_config_file(here) -> Path:
    return Path(here / "test-config.yaml")


@pytest.fixture
def test_config(test_config_file):
    with test_config_file.open() as fp:
        return yaml.safe_load(fp)


@pytest.fixture
def valid_docker_stack_file(here):
    return Path(here / "mocks" / "valid_docker_stack.yaml")


@pytest.fixture
def valid_docker_stack(valid_docker_stack_file):
    with valid_docker_stack_file.open() as fp:
        return yaml.safe_load(fp)


@pytest.fixture
def valid_config(here):
    with Path(here / "mocks" / "valid_config.yaml").open() as fp:
        return yaml.safe_load(fp)


@pytest.fixture
def loop():
    if platform.system() == "Windows":
        loop = asyncio.ProactorEventLoop()
        asyncio.set_event_loop(loop)
    else:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
    loop = asyncio.get_event_loop()
    yield loop
    loop.close()

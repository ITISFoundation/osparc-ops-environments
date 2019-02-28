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
def test_config(here):
    with Path(here / "test-config.yaml").open() as fp:
        return yaml.safe_load(fp)


@pytest.fixture
def async_subprocess_compatible_loop():
    if platform.system() == "Windows":
        loop = asyncio.ProactorEventLoop()
        asyncio.set_event_loop(loop)
    loop = asyncio.get_event_loop()
    yield loop
    loop.close()

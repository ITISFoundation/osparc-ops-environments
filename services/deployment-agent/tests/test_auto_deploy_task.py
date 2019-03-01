import pytest
from aiohttp import web
from servicelib.application_keys import APP_CONFIG_KEY

from simcore_service_deployment_agent import auto_deploy_task


@pytest.fixture
async def fake_app(test_config):
    app = web.Application()
    app[APP_CONFIG_KEY] = test_config
    yield app


async def test_setup_task(loop, fake_app):
    try:
        auto_deploy_task.setup(fake_app)
    except:
        pytest.fail("Unexpected error")

    try:
        await auto_deploy_task.start(fake_app)
        assert auto_deploy_task.TASK_NAME in fake_app
        await auto_deploy_task.cleanup(fake_app)
    except:
        pytest.fail("Unexpected error")

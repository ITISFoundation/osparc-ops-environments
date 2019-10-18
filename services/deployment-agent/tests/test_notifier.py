# pylint:disable=wildcard-import
# pylint:disable=unused-import
# pylint:disable=unused-variable
# pylint:disable=unused-argument
# pylint:disable=redefined-outer-name
# pylint:disable=protected-access

from pathlib import Path
from typing import Dict, List

import pytest
import yaml
from aiohttp import web
from yarl import URL

from simcore_service_deployment_agent import notifier


@pytest.fixture
def valid_notifier_config(here):
    with Path(here / "mocks" / "valid_notifier_config.yaml").open() as fp:
        return yaml.safe_load(fp)

@pytest.fixture
async def mattermost_server(loop, aiohttp_server):
    async def serve(routes: List[Dict]):
        app = web.Application()
        # fill route table
        async def hello(request):
            return web.json_response('Hello World')
        app.router.add_route('GET', '/', hello)
        for route in routes:
            app.router.add_route(route["method"], route["path"], route["handler"])
        server = await aiohttp_server(app)
        return server
    return serve

def _list_messages():
    return [
        "",
        "some fantastic message"
    ]

@pytest.mark.parametrize("message", _list_messages())
async def test_notify_mattermost(loop, valid_notifier_config, mattermost_server, message, aiohttp_client):

    async def handler(request):
        assert "Authorization" in request.headers
        assert valid_notifier_config["main"]["notifications"][0]["personal_token"] in request.headers["Authorization"]

        data = await request.json()
        assert "channel_id" in data
        assert data["channel_id"] == valid_notifier_config["main"]["notifications"][0]["channel_id"]
        assert "message" in data
        assert valid_notifier_config["main"]["notifications"][0]["message"] in data["message"]
        if message:
            assert message in data["message"]
            assert data["message"] == "{}\n{}".format(valid_notifier_config["main"]["notifications"][0]["message"], message)
        else:
            assert data["message"] == valid_notifier_config["main"]["notifications"][0]["message"]
        return web.json_response("message_sent", status=201)

    routes = [{
        "method": "POST",
        "path": "/api/v4/posts",
        "handler": handler
        }]
    server = await mattermost_server(routes)
    origin = URL.build(**{ k:getattr(server, k) for k in ("scheme", "host", "port")})
    valid_notifier_config["main"]["notifications"][0]["url"] = origin
    client = await aiohttp_client(server)
    await notifier.notify(valid_notifier_config, client.session, message)

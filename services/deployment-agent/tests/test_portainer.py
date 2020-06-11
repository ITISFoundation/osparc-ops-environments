# pylint:disable=wildcard-import
# pylint:disable=unused-import
# pylint:disable=unused-variable
# pylint:disable=unused-argument
# pylint:disable=redefined-outer-name
# pylint:disable=protected-access

import json
from asyncio import Future
from typing import Dict, List

import pytest
from aiohttp import web
from yarl import URL

from simcore_service_deployment_agent import exceptions, portainer


@pytest.fixture
async def portainer_server(loop, aiohttp_server):
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

async def test_request(loop, portainer_server, aiohttp_client):
    routes = []
    server = await portainer_server(routes)
    client = await aiohttp_client(server)

    origin = URL.build(**{ k:getattr(server, k) for k in ("scheme", "host", "port")})
    test_url = origin.with_path("/")
    test_method = "GET"

    await portainer._portainer_request(test_url, client.session, test_method)
    with pytest.raises(exceptions.ConfigurationError):
        test_url = origin.with_path("some_fantastic_path")
        await portainer._portainer_request(test_url, client.session, test_method)

async def test_authenticate(loop, portainer_server, aiohttp_client):
    async def handler(request):
        return web.json_response({"jwt":"someBearerCode"})

    routes = [{
        "method": "POST",
        "path": "/api/auth",
        "handler": handler
        }]
    server = await portainer_server(routes)
    client = await aiohttp_client(server)
    origin = URL.build(**{ k:getattr(server, k) for k in ("scheme", "host", "port")})
    bearer_code = await portainer.authenticate(origin, client.session, username="testuser", password="password")
    assert bearer_code == "someBearerCode"

async def test_first_endpoint_id(loop, portainer_server, aiohttp_client):
    async def handler(request: web.Request):
        return web.json_response([{"Id": 2}, {"Id": 5}])
    routes = [{
        "method": "GET",
        "path": "/api/endpoints",
        "handler": handler
    }]
    server = await portainer_server(routes)
    client = await aiohttp_client(server)
    origin = URL.build(**{ k:getattr(server, k) for k in ("scheme", "host", "port")})
    enpoint_id = await portainer.get_first_endpoint_id(origin, client.session, bearer_code="mybearerCode")
    assert enpoint_id == 2

async def test_get_swarm_id(loop, portainer_server, aiohttp_client):
    async def handler(request):
        return web.json_response({"ID":"someID"})

    routes = [{
        "method": "GET",
        "path": "/api/endpoints/1/docker/swarm",
        "handler": handler
        }]
    server = await portainer_server(routes)
    client = await aiohttp_client(server)
    origin = URL.build(**{ k:getattr(server, k) for k in ("scheme", "host", "port")})
    swarm_id = await portainer.get_swarm_id(origin, client.session, bearer_code="mybearerCode", endpoint_id=1)
    assert swarm_id == "someID"

async def test_stacks(loop, portainer_server, aiohttp_client):
    async def handler(request):
        return web.json_response([{"Name": "firstStack", "Id": "stackID"},
        {"Name": "secondStack", "Id": "secondID"}])

    routes = [{
        "method": "GET",
        "path": "/api/stacks",
        "handler": handler
        }]
    server = await portainer_server(routes)
    client = await aiohttp_client(server)
    origin = URL.build(**{ k:getattr(server, k) for k in ("scheme", "host", "port")})
    stacks_list = await portainer.get_stacks_list(origin, client.session, bearer_code="mybearerCode")
    assert len(stacks_list) == 2
    assert stacks_list[0]["Name"] == "firstStack"
    assert stacks_list[0]["Id"] == "stackID"
    assert stacks_list[1]["Name"] == "secondStack"
    assert stacks_list[1]["Id"] == "secondID"

    current_stack_id = await portainer.get_current_stack_id(origin, client.session, bearer_code="mybearerCode", stack_name="firstStack")
    assert current_stack_id == "stackID"

    current_stack_id = await portainer.get_current_stack_id(origin, client.session, bearer_code="mybearerCode", stack_name="fakestuff")
    assert not current_stack_id

async def test_create_stack(loop, portainer_server, valid_docker_stack, aiohttp_client):
    swarm_id = "1"
    stack_name = "some fake name"
    async def handler(request):
        assert "type" in request.query
        assert request.query["type"] == "1"
        assert "method" in request.query
        assert request.query["method"] == "string"
        assert "endpointId" in request.query
        assert request.query["endpointId"] == "1"

        data = await request.json()
        assert "Name" in data
        assert data["Name"] == stack_name
        assert "SwarmID" in data
        assert data["SwarmID"] == swarm_id
        assert "StackFileContent" in data
        assert json.loads(data["StackFileContent"]) == valid_docker_stack

        return web.json_response(data["StackFileContent"])

    async def handler_update(request):
        assert "endpointId" in request.query
        assert request.query["endpointId"] == "1"
        data = await request.json()
        assert "StackFileContent" in data
        assert json.loads(data["StackFileContent"]) == valid_docker_stack
        assert "Prune" in data
        assert data["Prune"]

        return web.json_response(data["StackFileContent"])

    routes = [{
        "method": "POST",
        "path": "/api/stacks",
        "handler": handler
        },
        {
        "method": "PUT",
        "path": "/api/stacks/{id}",
        "handler": handler_update
        }]
    server = await portainer_server(routes)
    client = await aiohttp_client(server)
    origin = URL.build(**{ k:getattr(server, k) for k in ("scheme", "host", "port")})
    bearer_code = "mybearerCode"
    endpoint = 1
    new_stack = await portainer.post_new_stack(origin, client.session, bearer_code=bearer_code,
                            swarm_id=swarm_id, endpoint_id=endpoint, stack_name=stack_name, stack_cfg=valid_docker_stack)

    updated_stack = await portainer.update_stack(origin, client.session, bearer_code=bearer_code, stack_id="1", endpoint_id=endpoint, stack_cfg=valid_docker_stack)


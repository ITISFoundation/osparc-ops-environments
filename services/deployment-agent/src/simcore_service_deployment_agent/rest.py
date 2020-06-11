""" Restful API subsystem

    - Loads and validates openapi specifications (oas)
    - Adds check and diagnostic routes
    - Activates middlewares
"""
import asyncio
import logging
from pathlib import Path
from pprint import pformat

from aiohttp import web
from servicelib import openapi
from servicelib.application_keys import APP_CONFIG_KEY
from servicelib.openapi import create_openapi_specs
from servicelib.rest_middlewares import append_rest_middlewares
from tenacity import before_sleep_log, retry, stop_after_attempt, wait_fixed
from yarl import URL

from . import rest_handlers
from .resources import resources
from .rest_config import APP_OPENAPI_SPECS_KEY, CONFIG_SECTION_NAME

log = logging.getLogger(__name__)


RETRY_WAIT_SECS = 2
RETRY_COUNT = 10

@retry( wait=wait_fixed(RETRY_WAIT_SECS),
        stop=stop_after_attempt(RETRY_COUNT),
        before_sleep=before_sleep_log(log, logging.INFO) )
async def get_specs(location):
    specs = await create_openapi_specs(location)
    return specs

def create_routes(specs):
    base_path = openapi.get_base_path(specs)

    log.debug("creating %s ", __name__)
    routes = []
    path, handle = '/', rest_handlers.check_health
    operation_id = specs.paths[path].operations['get'].operation_id
    routes.append( web.get(base_path+path, handle, name=operation_id) )

    path, handle = '/check/{action}', rest_handlers.check_action
    operation_id = specs.paths[path].operations['post'].operation_id
    routes.append( web.post(base_path+path, handle, name=operation_id) )

    return routes

def setup(app: web.Application, *, devel=False):
    """ Subsystem's setup

    :param app: aiohttp application
    :type app: web.Application
    :param devel: enables development mode, defaults to False
    :param devel: bool, optional
    """

    log.debug("Setting up %s %s...", __name__, "[DEVEL]" if devel else "")

    cfg = app[APP_CONFIG_KEY][CONFIG_SECTION_NAME]

    try:
        loop = asyncio.get_event_loop()
        location = cfg["location"]
        if not URL(location).host:
            if not Path(location).exists():
                # add resource location
                if resources.exists(location):
                    location = resources.get_path(location)

        specs = loop.run_until_complete(get_specs(location))

        # TODO: What if many specs to expose? v0, v1, v2 ... perhaps a dict instead?
        app[APP_OPENAPI_SPECS_KEY] = specs # validated openapi specs

    except openapi.OpenAPIError:
        # TODO: protocol when some parts are unavailable because of failure
        # Define whether it is critical or this server can still
        # continue working offering partial services
        log.exception("Invalid rest API specs. Rest API is DISABLED")
    else:
        # routes
        routes = create_routes(specs)
        log.debug("%s API routes:\n%s", CONFIG_SECTION_NAME,  pformat(routes))
        app.router.add_routes(routes)

        # middlewares
        base_path = openapi.get_base_path(specs)
        version  = cfg["version"]
        assert "/"+version == base_path, "Expected %s, got %s" %(version, base_path)
        append_rest_middlewares(app, base_path)

# alias
setup_rest = setup

__all__ = (
    'setup_rest'
)

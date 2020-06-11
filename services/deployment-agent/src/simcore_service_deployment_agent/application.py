""" Main's application module for simcore_service_deployment_agent service

    Functions to create, setup and run an aiohttp application provided a configuration object
"""
import asyncio
import logging
import platform

from aiohttp import web
from servicelib.application_keys import APP_CONFIG_KEY

from .auto_deploy_task import setup as setup_auto_deploy_task
from .rest import setup_rest

log = logging.getLogger(__name__)

def create(config, loop):
    log.debug("Initializing ... ")
    app = web.Application(loop=loop)
    app[APP_CONFIG_KEY] = config

    # TODO: here goes every package/plugin setups
    setup_rest(app)
    setup_auto_deploy_task(app)

    return app

def run(config, app=None):
    log.debug("Serving app ... ")
    if platform.system() == "Windows":
        loop = asyncio.ProactorEventLoop()
        asyncio.set_event_loop(loop)
    loop = asyncio.get_event_loop()

    if not app:
        app = create(config, loop)


    web.run_app(app,
        host=config["main"]["host"],
        port=config["main"]["port"])

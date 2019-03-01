import logging
from typing import Dict

from aiohttp import ClientSession
from yarl import URL

from .exceptions import ConfigurationError, AutoDeployAgentException

log = logging.getLogger(__name__)

async def notify_mattermost(mattermost_config: Dict):
    if mattermost_config["enabled"]:
        message = mattermost_config["message"]
        personal_token = mattermost_config["personal_token"]
        channel_id = mattermost_config["channel_id"]
        url = URL(mattermost_config["url"]).with_path("api/v4/posts")

        headers = {"Authorization": "Bearer {}".format(personal_token)}
        async with ClientSession() as client:
            async with client.post(url, headers=headers, json={"channel_id": channel_id, "message": message}) as resp:
                log.debug("request response received with code %s", resp.status)
                if resp.status == 201:
                    data = await resp.json()
                    return data
                if resp.status == 404:
                    log.error("could not find route in %s", url)
                    raise ConfigurationError("Could not authenticate with Portainer app in {}:\n {}".format(url, await resp.text()))
                log.error("Unknown error")
                raise AutoDeployAgentException("Unknown error while accessing Portainer app in {}:\n {}".format(url, await resp.text()))


async def notify(app_config: Dict):
    notify_configs = app_config["main"]["notifications"]
    for notify_config in notify_configs:
        if "mattermost" == notify_config["service"]:
            await notify_mattermost(notify_config)

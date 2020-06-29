import datetime
import json
import logging
from typing import Dict

from aiohttp import ClientSession
from yarl import URL

from .app_state import State
from .exceptions import AutoDeployAgentException, ConfigurationError

log = logging.getLogger(__name__)

async def notify_mattermost(mattermost_config: Dict, app_session: ClientSession, add_message: str):
    if mattermost_config["enabled"]:
        message = mattermost_config["message"]
        if add_message:
            message = f"{message}\n{add_message}"
        personal_token = mattermost_config["personal_token"]
        channel_id = mattermost_config["channel_id"]
        url = URL(mattermost_config["url"]).with_path("api/v4/posts")

        headers = {"Authorization": f"Bearer {personal_token}"}
        async with app_session.post(url, headers=headers, json={"channel_id": channel_id, "message": message}) as resp:
            log.debug("request response received with code %s", resp.status)
            if resp.status == 201:
                data = await resp.json()
                return data
            if resp.status == 404:
                log.error("could not find route in %s", url)
                raise ConfigurationError("Could not find channel within Mattermost app in {}:\n {}".format(url, await resp.text()))
            log.error("Unknown error")
            raise AutoDeployAgentException("Unknown error while accessing Mattermost app in {}:\n {}".format(url, await resp.text()))

async def notify_mattermost_header(mattermost_config: Dict, app_session: ClientSession, state: State, status_message: str):
    if mattermost_config["enabled"]:
        status_emoji = ":+1: "
        if state is State.FAILED:
            status_emoji = ":x:"
        elif state is State.PAUSED:
            status_emoji = ":x:"

        header_unique_name = mattermost_config["header_unique_name"]
        date = datetime.datetime.utcnow().isoformat(timespec='seconds')
        message = f"{header_unique_name} {status_emoji} {status_message} - {date} |"

        personal_token = mattermost_config["personal_token"]
        channel_id = mattermost_config["channel_id"]
        headers = {"Authorization": f"Bearer {personal_token}"}

        # get the current header to update it
        url = URL(mattermost_config["url"]).with_path(f"api/v4/channels/{channel_id}")
        current_header = ""
        async with app_session.get(url, headers=headers) as resp:
            log.debug("requested channel description: received with code %s", resp.status)
            if resp.status == 404:
                log.error("could not find route in %s", url)
                raise ConfigurationError("Could not find channel within Mattermost app in {}:\n {}".format(url, await resp.text()))
            if not resp.status == 200:
                log.error("Unknown error")
                raise AutoDeployAgentException("Unknown error while accessing Mattermost app in {}:\n {}".format(url, await resp.text()))
            data = await resp.json()
            log.debug("received data: %s", data)
            current_header = data["header"]

        new_header = message
        start_index = current_header.find(header_unique_name)
        if start_index != -1:
            # update the message instead
            lastindex = current_header.find("|", start_index)
            new_header = "{}{}{}".format(current_header[0:start_index], message, current_header[lastindex+1:])

        url = URL(mattermost_config["url"]).with_path(f"api/v4/channels/{channel_id}/patch")
        async with app_session.put(url, headers=headers, data=json.dumps({"header": new_header})) as resp:
            log.debug("requested patch channel description: response received with code %s", resp.status)
            if resp.status == 200:
                data = await resp.json()
                return data
            if resp.status == 404:
                log.error("could not find route in %s", url)
                raise ConfigurationError("Could not find channel within Mattermost app in {}:\n {}".format(url, await resp.text()))
            log.error("Unknown error")
            raise AutoDeployAgentException("Unknown error while accessing Mattermost app in {}:\n {}".format(url, await resp.text()))

async def notify(app_config: Dict, app_session: ClientSession, message: str=None):
    notify_configs = app_config["main"]["notifications"]
    for notify_config in notify_configs:
        if "mattermost" == notify_config["service"]:
            await notify_mattermost(notify_config, app_session, add_message=message)

async def notify_state(app_config: Dict, app_session: ClientSession, state: State, message: str):
    notify_configs = app_config["main"]["notifications"]
    for notify_config in notify_configs:
        if "mattermost" == notify_config["service"]:
            await notify_mattermost_header(notify_config, app_session, state, message)

import asyncio
import platform

import pytest

from simcore_service_deployment_agent import cmd_utils, exceptions


def test_valid_cmd():
    if platform.system() == "Windows":
        loop = asyncio.ProactorEventLoop()
        asyncio.set_event_loop(loop)
    loop = asyncio.get_event_loop()

    try:
        loop.run_until_complete(cmd_utils.run_cmd_line("whoami"))
    except exceptions.CmdLineError:
        pytest.fail("Unexpected error")


def test_invalid_cmd():
    if platform.system() == "Windows":
        loop = asyncio.ProactorEventLoop()
        asyncio.set_event_loop(loop)
    loop = asyncio.get_event_loop()

    with pytest.raises(exceptions.CmdLineError):
        loop.run_until_complete(cmd_utils.run_cmd_line("whoamiasd"))

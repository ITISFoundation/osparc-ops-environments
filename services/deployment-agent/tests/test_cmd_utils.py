# pylint:disable=wildcard-import
# pylint:disable=unused-import
# pylint:disable=unused-variable
# pylint:disable=unused-argument
# pylint:disable=redefined-outer-name

import pytest

from simcore_service_deployment_agent import cmd_utils, exceptions


async def test_valid_cmd(loop):
    try:
        await cmd_utils.run_cmd_line("whoami")
    except exceptions.CmdLineError:
        pytest.fail("Unexpected error")


async def test_invalid_cmd(loop):
    with pytest.raises(exceptions.CmdLineError):
        await cmd_utils.run_cmd_line("whoamiasd")

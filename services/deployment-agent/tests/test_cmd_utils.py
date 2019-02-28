# pylint:disable=wildcard-import
# pylint:disable=unused-import
# pylint:disable=unused-variable
# pylint:disable=unused-argument
# pylint:disable=redefined-outer-name

import pytest

from simcore_service_deployment_agent import cmd_utils, exceptions


def test_valid_cmd(async_subprocess_compatible_loop):
    try:
        async_subprocess_compatible_loop.run_until_complete(
            cmd_utils.run_cmd_line("whoami"))
    except exceptions.CmdLineError:
        pytest.fail("Unexpected error")


def test_invalid_cmd(async_subprocess_compatible_loop):
    with pytest.raises(exceptions.CmdLineError):
        async_subprocess_compatible_loop.run_until_complete(
            cmd_utils.run_cmd_line("whoamiasd"))

import asyncio
import logging

from .exceptions import CmdLineError

log = logging.getLogger(__name__)


async def run_cmd_line(cmd):
    proc = await asyncio.create_subprocess_shell(
        cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
    )
    stdout, stderr = await proc.communicate()
    await proc.wait()
    log.debug("[{%s}] exited with %s]", cmd, proc.returncode)

    if proc.returncode > 0:
        error_data = ""
        if stderr:
            error_data = stderr.decode()
            log.debug("\n[stderr]%s", error_data)
        raise CmdLineError(cmd, error_data)

    if stdout:
        data = stdout.decode()
        log.debug("\n[stdout]%s", data)
        return data

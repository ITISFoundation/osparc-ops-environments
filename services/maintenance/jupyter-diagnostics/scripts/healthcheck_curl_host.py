#!/bin/python3
""" Healthcheck script to run inside docker

References:
    - https://docs.docker.com/engine/reference/builder/#healthcheck
    - why not to use curl instead of a python script? See https://blog.sixeyed.com/docker-healthchecks-why-not-to-use-curl-or-iwr/
"""

import os
import sys

from urllib.request import urlopen

SUCCESS, UNHEALTHY = 0, 1

# Disabled if boots with debugger
ok = os.environ.get("SC_BOOT_MODE").lower() == "debug"

# Queries host
ok = ok or urlopen("{host}{baseurl}".format(
        host=sys.argv[1],
        baseurl=os.environ.get("SIMCORE_NODE_BASEPATH", "")) # adds a base-path if defined in environ
        ).getcode() == 200

sys.exit(SUCCESS if ok else UNHEALTHY)

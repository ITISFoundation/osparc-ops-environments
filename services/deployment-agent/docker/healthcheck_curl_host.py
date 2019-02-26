#!/bin/python

import json
import os
import sys
from urllib.request import urlopen

BOOTS_WITH_DEBUGGER = "2"
if os.environ.get("DEBUG") == BOOTS_WITH_DEBUGGER:
    # Healthcheck disabled with service is boot with a debugger
    sys.exit()
else:
    response = urlopen("{host}{baseurl}".format(host=sys.argv[1], baseurl=os.environ.get("SIMCORE_NODE_BASEPATH", "")))
    if response.status != 200:
        sys.exit(1)
    else:
        data = json.loads(response.read())
        sys.exit(1 if data["data"]["status"] == "SERVICE_FAILED" else 0)

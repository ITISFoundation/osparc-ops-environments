#!/bin/bash
# as of http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

bash ci/helpers/dockerhub_login.bash
pushd services/deployment-agent; make push ; popd

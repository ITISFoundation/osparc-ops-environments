#!/bin/bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

install() {
    bash ci/helpers/ensure_python_pip.bash
    pip3 install -r ci/github/system-testing/requirements.txt
    pushd services/deployment-agent; make build ; popd
    pip list -v
    docker images
    # start portainer (dependency)
    pushd services/portainer; make up; popd
    pushd services/deployment-agent;
    # use the config file for testing not the default
    cp tests/mocks/valid_system_test_config.yaml deployment_config.default.yaml
    make up
    popd
    docker service ls
}

test() {
    pytest --cov-append --color=yes --cov-report=term-missing --cov-report=xml --cov=services/deployment-agent -v ci/github/system-testing/tests
}

# Check if the function exists (bash specific)
if declare -f "$1" > /dev/null
then
  # call arguments verbatim
  "$@"
else
  # Show a helpful error
  echo "'$1' is not a known function name" >&2
  exit 1
fi

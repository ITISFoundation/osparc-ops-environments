#!/bin/sh
set -o errexit
set -o nounset

IFS=$(printf '\n\t')

INFO="INFO: [$(basename "$0")] "

# BOOTING application ---------------------------------------------
echo "$INFO" "Booting in ${SC_BOOT_MODE} mode ..."
echo "  User    :$(id "$(whoami)")"
echo "  Workdir :$(pwd)"

APP_CONFIG=config-prod.yaml
if [ "${SC_BUILD_TARGET}" = "development" ]
then
  echo "$INFO" "Environment :"
  printenv  | sed 's/=/: /' | sed 's/^/    /' | sort
  echo "$INFO" "Python :"
  python --version | sed 's/^/    /'
  command -v python | sed 's/^/    /'

  APP_CONFIG=/home/scu/host-dev.yaml

  cd services/deployment-agent || exit 1
  pip --no-cache-dir install -r requirements/dev.txt
  cd - || exit 1

  echo "$INFO" "PIP :"
  pip list | sed 's/^/    /'
fi


# RUNNING application ----------------------------------------
if [ "${SC_BOOT_MODE}" = "debug-ptvsd" ]
then
  echo
  echo "PTVSD Debugger initializing in port 3000"
  python3 -m ptvsd --host 0.0.0.0 --port 3000 -m simcore_service_deployment_agent --config $APP_CONFIG
else
  simcore-service-deployment-agent --config $APP_CONFIG
fi

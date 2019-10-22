#!/bin/sh
#

# BOOTING application ---------------------------------------------
echo "Booting in ${SC_BOOT_MODE} mode ..."
echo "  User    :`id $(whoami)`"
echo "  Workdir :`pwd`"

if [[ ${SC_BUILD_TARGET} == "development" ]]
then
  echo "  Environment :"
  printenv  | sed 's/=/: /' | sed 's/^/    /' | sort
  #--------------------

  APP_CONFIG=/home/scu/host-dev.yaml

  cd services/deployment-agent
  $SC_PIP install --user -r requirements/dev.txt
  cd /devel

  #--------------------
  echo "  Python :"
  python --version | sed 's/^/    /'
  which python | sed 's/^/    /'
  echo "  PIP :"
  $SC_PIP list | sed 's/^/    /'

elif [[ ${SC_BUILD_TARGET} == "production" ]]
then
  APP_CONFIG=config-prod.yaml
fi


# RUNNING application ----------------------------------------
if [[ ${SC_BOOT_MODE} == "debug-ptvsd" ]]
then
  echo
  echo "PTVSD Debugger initializing in port 3000"
  python3 -m ptvsd --host 0.0.0.0 --port 3000 -m simcore_service_deployment_agent --config $APP_CONFIG
else
  simcore-service-deployment-agent --config $APP_CONFIG
fi

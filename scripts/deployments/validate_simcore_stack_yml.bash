#!/bin/bash
set -o nounset
set -o pipefail
#
# This bash script expects the following environment variables to be set:
# - PREFIX_STACK_NAME: prefix of the stack name
#
export COMPOSE_FILE=simcore_stack.yml
export SETTINGS_BINARY_PATH=/home/scu/.venv/bin
#
export SERVICES_PREFIX=${PREFIX_STACK_NAME}
exit_code=0
# Download version-pinned yq binary
python -c "import urllib.request,os,sys,urllib; f = open(os.path.basename(sys.argv[1]), 'wb'); f.write(urllib.request.urlopen(sys.argv[1]).read()); f.close();" https://github.com/mikefarah/yq/releases/download/v4.29.2/yq_linux_amd64
mv yq_linux_amd64 yq
chmod +x yq
_yq=$(realpath ./yq)
export _yq
#
# start
#
for service in $($_yq e '.services | keys | .[]' ${COMPOSE_FILE}); do
    export TARGETNAME=${service#"${SERVICES_PREFIX}"_}
    #  continue if the service == director since it doesnt have settings
    if [ "${TARGETNAME}" == "director" ]; then
        continue
    fi
    if [ "${TARGETNAME}" == "migration" ]; then
        continue
    fi
    if [ "${TARGETNAME}" == "postgres" ]; then
        continue
    fi
    if [ "${TARGETNAME}" == "rabbit" ]; then
        continue
    fi
    if [ "${TARGETNAME}" == "redis" ]; then
        continue
    fi
    if [ "${TARGETNAME}" == "traefik" ]; then
        continue
    fi
    if [ "${TARGETNAME}" == "traefik_api" ]; then
        continue
    fi
    if [ "${TARGETNAME}" == "whoami" ]; then
        continue
    fi
    export TARGETFILE="simcore-service"
    echo TARGETFILE="${TARGETFILE}"
    echo "Assuming targetfile in ${SETTINGS_BINARY_PATH}/${TARGETFILE}"
    echo "Checking ${SETTINGS_BINARY_PATH}/${TARGETFILE}"
    # Pull image from registry, just in case
    docker compose --file ${COMPOSE_FILE} pull "${service}"
    #
    if docker compose --file ${COMPOSE_FILE} run --rm "${service}" test -f "${SETTINGS_BINARY_PATH}"/"${TARGETFILE}" >/dev/null 2>&1; then
        service_name="${service#*_}"
        echo "FOUND_EXECUTABLE=${SETTINGS_BINARY_PATH}/$service_name"
        export FOUND_EXECUTABLE="${SETTINGS_BINARY_PATH}/$service_name"
        if docker compose --file ${COMPOSE_FILE} run --entrypoint "${FOUND_EXECUTABLE}" --rm "${service}" settings --as-json >/dev/null 2>&1; then
            echo "SUCCESS: Validation of environment variables for ${service}"
        else
            echo "ERROR: Validation of environment variables for ${service} failed"
            docker compose --file ${COMPOSE_FILE} run --entrypoint "${FOUND_EXECUTABLE}" --rm "${service}" settings --as-json
            exit_code=1
        fi
    else
        echo "WARN: Settings executable not found for ${service}"
    fi

    echo "--------------------------"
done
exit $exit_code

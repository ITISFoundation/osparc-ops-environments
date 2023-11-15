#!/bin/bash
set -o nounset
set -o pipefail
set -x
export COMPOSE_FILE=simcore_stack.yml
export SETTINGS_BINARY_PATH=/home/scu/.venv/bin
export SERVICES_PREFIX=${PREFIX_STACK_NAME}
exit_code=0
for service in $(yq e '.services | keys | .[]' ${COMPOSE_FILE})
do
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
    export TARGETFILE="simcore-service-${TARGETNAME}"
    echo TARGETFILE="${TARGETFILE}"
    echo "Assuming targetfile in ${SETTINGS_BINARY_PATH}/${TARGETFILE}"
    echo "Checking ${SETTINGS_BINARY_PATH}/${TARGETFILE}"
    if docker compose --file ${COMPOSE_FILE} run --rm "${service}" test -f "${SETTINGS_BINARY_PATH}"/"${TARGETFILE}" > /dev/null 2>&1; then
        echo "FOUND_EXECUTABLE=${SETTINGS_BINARY_PATH}/$TARGETFILE"
        export FOUND_EXECUTABLE="${SETTINGS_BINARY_PATH}/$TARGETFILE"
        if docker compose --file ${COMPOSE_FILE} run --entrypoint "${FOUND_EXECUTABLE}" --rm "${service}" settings --as-json > /dev/null 2>&1; then
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

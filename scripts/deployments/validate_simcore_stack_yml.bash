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
# Check if the Docker Compose file has a top-level secrets section
if $_yq e ".secrets" ${COMPOSE_FILE} > /dev/null; then
    # Generate a random private key file
    echo "Generating a random private key file on the host"
    docker run --rm -v /tmp:/tmp itisfoundation/ci-provisioned-ubuntu:latest openssl genpkey -algorithm RSA -out /tmp/random_private_key.pem
    # Iterate over the secrets
    for secret in $($_yq e ".secrets | keys | .[]" ${COMPOSE_FILE}); do
        # Get the file path
        if $_yq e ".secrets.${secret} | has(\"file\")" ${COMPOSE_FILE} > /dev/null; then
            file_path=$($_yq e ".secrets.${secret}.file" ${COMPOSE_FILE})

            # Check if it's a .pem file and replace the path
            if [[ $file_path == *.pem ]] || [[ $file_path == *.crt ]];  then
                $_yq e -i ".secrets.${secret}.file = \"/tmp/random_private_key.pem\"" ${COMPOSE_FILE}
                echo "Replaced secret \"$secret\" at $file_path with a random private key."
            else
                echo "Error: Found a secret \"$secret\" that is not a .pem file: $file_path"
                exit 1
            fi
        fi
    done
else
    echo "Error: No top-level secrets section found in the Docker Compose file"
    exit 1
fi
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
    if [ "${TARGETNAME}" == "static-webserver" ]; then
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
    #  Continue if the service is efs-guardian, as it cannot start because mounting the AWS Distributed Elastic File System to the runner would be required.
    if [ "${TARGETNAME}" == "efs-guardian" ]; then
        continue
    fi
    if [ "${TARGETNAME}" == "docker-api-proxy" ]; then
        continue
    fi
    if [ "${TARGETNAME}" == "traefik-configuration-placeholder" ]; then
        continue
    fi
    if [ "${TARGETNAME}" == "ops-traefik-configuration-placeholder" ]; then
        continue
    fi
    export TARGET_BINARY="simcore-service"
    echo "Assuming TARGET_BINARY in ${SETTINGS_BINARY_PATH}/${TARGET_BINARY}"
    # Pull image from registry, just in case
    docker compose --file ${COMPOSE_FILE} pull --policy always "${service}"
    #
    export TARGET_EXECUTABLE="${SETTINGS_BINARY_PATH}/${TARGET_BINARY}"
    if docker compose --file ${COMPOSE_FILE} run --entrypoint "${TARGET_EXECUTABLE}" --rm "${service}" settings --as-json >/dev/null 2>&1; then
        echo "SUCCESS: Validation of environment variables for ${service}"
    else
        echo "ERROR: Validation of environment variables for ${service} failed"
        docker compose --file ${COMPOSE_FILE} run --entrypoint "${TARGET_EXECUTABLE}" --rm "${service}" settings --as-json
        exit_code=1
    fi

    echo "--------------------------"
done
exit $exit_code

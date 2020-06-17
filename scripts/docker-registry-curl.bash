#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

# REQUIREMENTS
#  curl
#  jq
#  base64
#  egrep
#  cut
#  sed

#set -x

console() {
    :
    return
    echo "${@}"
}

main() {
    OUTPUT=$(curl "${@}" --head -vsi 2>&1 | grep --extended-regexp "^<|^>")
    REGISTRY_HOST=$(echo "${OUTPUT}" | grep --extended-regexp "> Host: " | cut --delimiter=: --fields=2 | sed --expression='s/^[[:space:]]*//' --expression='s/[[:space:]]*$//')
    WWW_AUTHENTICATE=$(echo "${OUTPUT}" | grep --extended-regexp "< www-authenticate: " | cut --delimiter=: --fields=2- | sed --expression='s/^[[:space:]]*//' --expression='s/[[:space:]]*$//')

    console "${OUTPUT}"
    console "${REGISTRY_HOST}"
    console "${WWW_AUTHENTICATE}"

    if [ "x${WWW_AUTHENTICATE}" != "x" ];then
        # we need to get a token
        DOCKER_AUTH_TYPE=$(echo "${WWW_AUTHENTICATE}" | cut --delimiter=" " --fields=1)
        DETAILS=$(echo "${WWW_AUTHENTICATE}" | cut --delimiter=" " --fields=2-)
        console "${DOCKER_AUTH_TYPE}"
        console "${DETAILS}"
        console "${REGISTRY_HOST}"
        if [ "${DOCKER_AUTH_TYPE}" == "Bearer" ];then
            REALM=$(echo "${DETAILS}" | cut --delimiter=',' --fields=1 | cut --delimiter="=" --fields=2 | tr --delete '"')
            SERVICE=$(echo "${DETAILS}" | cut --delimiter=',' --fields=2 | cut --delimiter="=" --fields=2 | tr --delete '"')
            SCOPE=$(echo "${DETAILS}" | cut --delimiter=',' --fields=3 | cut --delimiter="=" --fields=2 | tr --delete '"')
            if [ -v DOCKER_AUTH ];then
                :
            elif [[ "x${DOCKER_USERNAME}" != "x" && "x${DOCKER_PASSWORD}" != "x" ]];then
                DOCKER_AUTH="${DOCKER_USERNAME}:${DOCKER_PASSWORD}"
            elif [ -e ~/.docker/config.json ];then
                DOCKER_AUTH=$(jq -r ".[\"auths\"][\"${REGISTRY_HOST}\"][\"auth\"]" ~/.docker/config.json | base64 -d)
            fi
            console "${REALM}"
            console "${SERVICE}"
            console "${SCOPE}"
            console "${DOCKER_AUTH}"
            if [ -v DOCKER_AUTH ];then
                DOCKER_AUTH_TOKEN=$(curl -m 10 -u "${DOCKER_AUTH}" "${REALM}?service=${SERVICE}&scope=${SCOPE}" -s 2>/dev/null | jq -r .token | xargs echo)
            fi
            console "${DOCKER_AUTH_TOKEN}"
        fi
    fi

    curl -H "Authorization: ${DOCKER_AUTH_TYPE} ${DOCKER_AUTH_TOKEN}" "${@}"
}

main "${@}"

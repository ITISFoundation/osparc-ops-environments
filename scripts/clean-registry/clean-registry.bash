#!/bin/bash
#
# Delete images from the registry. Registry garbage collector needs to be run after this script
#
# TODO : create functionality for deleting manifests without tags
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'
# shellcheck disable=1090,1091
source .env

IFS=', ' read -r -a tags <<< "${IMAGES_TAGS}"

for tag in "${tags[@]}"
do
        echo "Deleting image with tag ${tag}"
        # We need to query the image digest
        digest=$(curl -I -H "Accept: application/vnd.docker.distribution.manifest.v2+json" -u "${REGISTRY_USER}":"${REGISTRY_PASSWORD}" "${REGISTRY_URL}""${IMAGES_NAME}"/manifests/"${tag}" | grep docker-content-digest: |  awk '{print $2}' FS=' ' | tr -d '\r')
        # We can delete the image using the digest
        curl_answer=$(curl -X DELETE -u "${REGISTRY_USER}":"${REGISTRY_PASSWORD}" "${REGISTRY_URL}${IMAGES_NAME}/manifests/${digest}")
        echo "${curl_answer}"
done

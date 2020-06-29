#!/bin/bash
#
# Deploys in local host
#
#
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

docker run \
-v /etc/ssl/certs:/etc/ssl/certs:ro \
--network host \
--environment MC_HOST_local="https://${S3_ACCESS_KEY}:${S3_SECRET_KEY}@${S3_ENDPOINT}" \
minio/mc mb --ignore-existing local/$1 

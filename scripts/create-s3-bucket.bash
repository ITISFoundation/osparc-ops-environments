#!/bin/bash
#
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
--env MC_HOST_local="https://${S3_ACCESS_KEY}:${S3_SECRET_KEY}@${STORAGE_DOMAIN}" \
minio/mc:RELEASE.2023-06-19T19-31-19Z mb --insecure --ignore-existing local/"$1"

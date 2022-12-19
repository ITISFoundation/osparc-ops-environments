#!/bin/bash
#
# Give current usage about minio buckets in GB
# To run this, make sure the env-vars ACCESS1, ACCESS2, SOURCE1, SOURCE2, ENDPOINT1, ENDPOINT2, S3_BUCKET_NAME are set
#
#
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

# Loads configurations variables
repo_basedir=$(git rev-parse --show-toplevel)
if [ -s "$repo_basedir/.config.location" ]
then
repo_config=$(cat "$repo_basedir"/.config.location)
if [ -s "$repo_config" ]
then
set -o allexport
# shellcheck disable=1090,1091
source "${repo_config}"
set +o allexport
else
echo "File ${repo_config} does not exist or is empty. Aborting." && exit 1
fi
else
echo "File $repo_basedir/.config.location does not exist or is empty. Aborting." && exit 1
fi

# Assertions
if [[ ${ENDPOINT2} == *"https://"* ]]; then
  echo "ERROR:" && echo "ENDPOINT2=${ENDPOINT2}" && echo "This script will not work if the env-var ENDPOINT2 contains the prefix \"https://\". Please remove it." && exit 1
fi
# Assertions
if [[ ${ENDPOINT1} == *"https://"* ]]; then
  echo "ERROR:" && echo "ENDPOINT1=${ENDPOINT1}" && echo "This script will not work if the env-var ENDPOINT1 contains the prefix \"https://\". Please remove it." && exit 1
fi

echo "Infos for Simcore bucket :  ${S3_BUCKET}"
docker run \
-v /etc/ssl/certs:/etc/ssl/certs:ro \
--network host \
--env MC_HOST_myminio1r="https://${ACCESS1}:${SOURCE1}@${ENDPOINT1}" \
--env MC_HOST_myminio2="https://${ACCESS2}:${SOURCE2}@${ENDPOINT2}" \
minio/mc mirror myminio1/"${S3_BUCKET_NAME}" myminio2/"${S3_BUCKET_NAME}" --watch

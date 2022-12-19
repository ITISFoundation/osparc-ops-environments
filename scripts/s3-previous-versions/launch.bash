#!/bin/bash
# This script restore S3 objects to a previous versionized state
#

set -o nounset
set -o pipefail
IFS=$'\n\t'

set -o allexport
# shellcheck disable=1090,1091
source .env
set +o allexport
git clone https://github.com/angeloc/s3-pit-restore
pushd s3-pit-restore || exit 1
s3-pit-restore "$@"
popd || exit 1
rm -rf s3-pit-restore

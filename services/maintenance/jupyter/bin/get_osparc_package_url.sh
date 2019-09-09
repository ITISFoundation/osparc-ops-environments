#!/bin/bash
#
# Gets URL to install a python package from osparc-simcore of a given branch or commit as
#
#  pip install -e $(URL)
#
# provided 
#    PACKAGE_FOLDER_NAME and BRANCH_OR_COMMIT (defaults: master)
#
#
# Usage:
#   pip install  $(bash ./get_osparc_package_url.sh postgres-database)
#   pip install  $(bash ./get_osparc_package_url.sh postgres-database 6dd819f0bf03fa7be92f6b41ebfac503b52b5317)
#
#

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

PACKAGE_FOLDER_NAME=$1
BRANCH_OR_COMMIT=${2:-master}


# FIXME: Notice that pip sometimes fails to install subdirectories https://github.com/pypa/pip/issues/3660
URL="git+https://github.com/ITISFoundation/osparc-simcore.git@${BRANCH_OR_COMMIT}#egg=${PACKAGE_FOLDER_NAME}&subdirectory=packages/${PACKAGE_FOLDER_NAME}"
echo $URL

#!/bin/bash
#
# This script assumed a clone of the osparc-simcore repo to be present in `"$repo_basedir"/../osparc-simcore`
#
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -o errexit
set -o nounset
set -o pipefail
# For debugging purposes, uncomment this and get every executed bash command printed to the console for tracing.
#set -x
#######
#
IFS=$'\n\t'

# Paths
this_script_dir=$(dirname "$0")
repo_basedir=$(git rev-parse --show-toplevel)
# shellcheck disable=1090,1091
source "$repo_basedir"/scripts/portable.sh
# Source bash logging tools
# shellcheck disable=1090,1091
source "$repo_basedir"/scripts/logger.bash
repo_config=$(cat "$repo_basedir"/.config.location)
#####################

log_info "Starting preperations..."
#####################
# Loads configurations variables
# See https://askubuntu.com/questions/743493/best-way-to-read-a-config-file-in-bash
set -o allexport
# shellcheck disable=1090,1091
source "${repo_config}"
set +o allexport
#
cd "$repo_basedir" || exit 1

pushd "$repo_basedir"/../osparc-simcore
cp services/docker-compose.yml "$repo_basedir"
popd

cp "$repo_config" "$repo_basedir"

cd "$repo_basedir"

log_info "Creating stack.yml file..."
scripts/deployments/compose_stack_yml.bash

log_info "Adding prefix $PREFIX_STACK_NAME to all services..."
./yq "with(.services; with_entries(.key |= \"${PREFIX_STACK_NAME}_\" + .))" stack.yml >"$this_script_dir"/stack_with_prefix.yml

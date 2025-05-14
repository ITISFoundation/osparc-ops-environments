#!/bin/bash
#
# Deploy the oSparc Simcore Full Stack
#
#
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -o errexit
set -o nounset
set -o pipefail
#######
#
IFS=$'\n\t'

function substitute_environs
{
    # NOTE: be careful that no variable with $ are in .env or they will be replaced by envsubst unless a list of variables is given
    envsubst < "${1:-"Missing File"}" > "${2}"
}

function call_make
{
    make --no-print-directory --directory "${1:-"Missing Directory"}" "${@:2:$#}"
}

# Silent pushd via https://stackoverflow.com/a/25288289
pushd () {
    command pushd "$@" > /dev/null
}

# shellcheck disable=SC2034
declare psed # fixes issue with not finding psed

# shellcheck disable=1090,1091
source "$( dirname "${BASH_SOURCE[0]}" )/../portable.sh"

# Paths
repo_basedir=$(git rev-parse --show-toplevel)
repo_config=$(cat "$repo_basedir"/.config.location)

# Source bash logging tools
# shellcheck disable=1090,1091
source "$repo_basedir"/scripts/logger.bash

# Define script variables, initialize with defaults
# 0: True
# 1: False
vcs_check=0
minio_enabled=1
start_simcore=0
start_opsstack=0
stack_target=local

usage="$(basename "$0") [-h] [--key=value]

Deploys all the osparc-ops stacks and the simcore stack.
NOTE: This script was used in the past to deploy to server / production systems, now it is only used for local dev deployments.
NOTE: Server deployments now use CD pipelines via gitlab.

where keys are:
    -h, --help  show this help text
    --start_simcore             (default: ${start_simcore})
    --minio_enabled             (default: ${minio_enabled})
    --start_opsstack            (default: ${start_opsstack})
    --stack_target              (default: ${stack_target})
    --vcs_check         (default: ${vcs_check})"

for i in "$@"; do
    case $i in # Infos on bash case statements https://linuxize.com/post/bash-case-statement/
        --start_opsstack=*)
        start_opsstack="${i#*=}"
        ;;
        ##
        --minio_enabled=*)
        minio_enabled="${i#*=}"
        ;;
        ##
        --start_simcore=*)
        start_simcore="${i#*=}"
        ;;
        ##
        --stack_target=*)
        stack_target="${i#*=}"
        ;;
        ##
        --vcs_check=*)
        vcs_check="${i#*=}"
        ;;
        ##
        :|--help|-h)
        echo "$usage" && exit 0
        shift
        ;;
    esac
done

### ASSERT VALID INPUT PARAMETERS
if [ "$start_opsstack" -eq "1" ]; then
    if [ "$start_simcore" -eq "1" ]; then
        error_exit "start_opsstack and start_simcore cannot both be set to 1. Aborting."
    fi
fi
listOfAllowedStackTargets="master dalco aws public local vagrant"
if ! echo "$listOfAllowedStackTargets" | grep -w -q "$stack_target"; then # via https://stackoverflow.com/a/8063284
    error_exit "stack_target $stack_target is not allowed (allowed targets: $listOfAllowedStackTargets). Aborting."
fi
###

# Loads configurations variables
# See https://askubuntu.com/questions/743493/best-way-to-read-a-config-file-in-bash
set -o allexport
# shellcheck disable=1090,1091
source "${repo_config}"
set +o allexport

log_info "Deploying osparc for $1 cluster on ${MACHINE_FQDN}, using credentials $SERVICES_USER:$SERVICES_PASSWORD"


# -------------------------------- ASSERTIONS -------------------------------
if [ "$vcs_check" -eq 0 ]; then
    log_info "Asserting that there are no uncommited changes in the config-files docker-compose-deploy and .env ..."
    pushd "${repo_basedir}"/services/simcore;
    call_make "." compose-"$1" > /dev/null
    popd

    # Check if current branch is up to date with origin/main
    # shellcheck disable=SC1083
    if [ "$(git rev-parse HEAD)" != "$(git rev-parse @{u})" ]; then
        error_exit "Current branch is not up to date with origin/main. Aborting."
    fi

    # Check if current branch is clean
    if [ -n "$(git status --porcelain)" ]; then
        error_exit "Current branch is not clean. Aborting."
    fi

    # Check if current branch is not ahead of origin/master
    # shellcheck disable=SC1083
    if [ "$(git rev-parse HEAD)" != "$(git rev-parse @{u})" ]; then
        error_exit "Current branch is ahead of origin/main. Aborting."
    fi

# check if there are uncommited changes in the repo, abort if this is the case.
pushd "$(dirname "${repo_config}")"
config_repo_current_git_branch=$(git rev-parse --abbrev-ref HEAD)
for path in $(dirname "${repo_config}")/repo.config
do
    if ! git diff origin/"${config_repo_current_git_branch}" --quiet --exit-code "$path"; then
        error_exit "$path is modified (w.r.t. origin), please commit, push your changes and restart the script";
    fi
done
popd
fi
# ---------------------------- END ASSERTIONS -------------------------------

if [ "$start_opsstack" -eq 0 ]; then

    # -------------------------------- TRAEFIK -------------------------------
    log_info "starting traefik..."
    pushd "${repo_basedir}"/services/traefik
    call_make "." up-"$stack_target"
    popd

    # -------------------------------- PORTAINER ------------------------------
    log_info "starting portainer..."
    pushd "${repo_basedir}"/services/portainer
    call_make "." up-"$stack_target"
    popd

    # -------------------------------- Redis commander-------------------------------
    log_info "starting redis commander..."
    pushd "${repo_basedir}"/services/redis-commander
    call_make "." up-"$stack_target"
    popd

    # -------------------------------- JAEGER -------------------------------
    log_info "starting jaeger..."
    service_dir="${repo_basedir}"/services/jaeger
    pushd "${service_dir}"
    call_make "." up-"$stack_target"
    popd

    # -------------------------------- Adminer -------------------------------
    log_info "starting adminer..."
    service_dir="${repo_basedir}"/services/adminer
    pushd "${service_dir}"
    call_make "." up-"$stack_target"
    popd

    # only start minio for the local deployment
    #
    if [ "$minio_enabled" -eq 0 ]; then
        # -------------------------------- Minio -------------------------------
        # In the .env, MINIO_NUM_MINIOS and MINIO_NUM_PARTITIONS need to be set at 1 to work without labelling the nodes with minioX=true
        log_info "starting minio..."
        service_dir="${repo_basedir}"/services/minio
        pushd "${service_dir}"
        call_make "." up-"$stack_target"
        popd

        log_info "waiting for minio to run...don't worry..."
        while [ ! "$(/usr/bin/curl -s -o /dev/null -I -w "%{http_code}" --max-time 10 https://"${STORAGE_DOMAIN}"/minio/health/ready)" = 200 ]; do
            log_info "waiting for minio to run..."
            sleep 5s
        done
    fi

    # -------------------------------- REGISTRY -------------------------------
    log_info "starting registry..."
    service_dir="${repo_basedir}"/services/registry
    pushd "${service_dir}"
    call_make "." up-"$stack_target"
    popd


    # -------------------------------- Filestash: S3 Tools --------------------------------
    log_info "starting filestash..."
    service_dir="${repo_basedir}"/services/filestash
    pushd "${service_dir}"
    call_make "." up-"$stack_target"
    popd

    # -------------------------------- APPMOTION GATEWAY -------------------------------
    log_info "starting appmotion-gateway..."
    pushd "${repo_basedir}"/services/appmotion_gateway
    call_make "." up-"$stack_target"
    popd

    # -------------------------------- MONITORING -------------------------------
    log_info "starting monitoring..."
    # Pushd because a call with call_make trigger a strange behavior
    pushd "${repo_basedir}"/services/monitoring;
    call_make "." up-"$stack_target";
    popd

    # -------------------------------- ADMIN-PANELS -------------------------------

    log_info "starting admin-panels..."
    # Check if the stack 'admin-panels' exists and delete it if it does
    # shellcheck disable=2015
    docker stack ls | grep -q admin-panels && docker stack rm admin-panels >/dev/null 2>&1 || true
    # Pushd because a call with call_make trigger a strange behavior
    pushd "${repo_basedir}"/services/admin-panels;
    call_make "." up-"$stack_target";
    popd

    # -------------------------------- LOGGING -------------------------------
    log_info "starting logging..."
    service_dir="${repo_basedir}"/services/logging
    pushd "${service_dir}"
    call_make "." up-"$stack_target"
    sleep 1
    call_make "." configure
    popd
fi
if [ "$start_simcore" -eq 0 ]; then
    log_info "starting simcore..."
    service_dir="${repo_basedir}"/services/simcore
    pushd "${service_dir}"
    call_make "." up-"$stack_target"
    popd
fi

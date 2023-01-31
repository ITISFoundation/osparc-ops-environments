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
disable_vcs_check=1
minio_enabled=1
start_simcore=0
start_opsstack=0
stack_target=local
without_deploy_agent=1

usage="$(basename "$0") [-h] [--key=value]

Deploys all the osparc-ops stacks and the simcore stack.

where keys are:
    -h, --help  show this help text
    --start_simcore             (default: ${start_simcore})
    --minio_enabled             (default: ${minio_enabled})
    --start_opsstack            (default: ${start_opsstack})
    --stack_target              (default: ${stack_target})
    --disable_vcs_check         (default: ${disable_vcs_check})
    --without_deploy_agent      (default: ${without_deploy_agent})"

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
        --disable_vcs_check=*)
        disable_vcs_check="${i#*=}"
        ;;
        ##
        --without_deploy_agent=*)
        without_deploy_agent="${i#*=}"
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

# Generate hashed traefik password
rehasedTraefikPassword=$(docker run --rm --entrypoint openssl alpine/openssl passwd -"$(echo "$TRAEFIK_PASSWORD" | cut -d "\$" -f2)" -salt "$(echo "$TRAEFIK_PASSWORD" | cut -d "\$" -f3)" "$SERVICES_PASSWORD")
if [ "${rehasedTraefikPassword}" != "$TRAEFIK_PASSWORD" ]; then
    $psed --in-place "s|TRAEFIK_PASSWORD=.*|TRAEFIK_PASSWORD='$(docker run --rm --entrypoint htpasswd registry:2.6 -nb "$SERVICES_USER" "$SERVICES_PASSWORD" | cut -d ':' -f2)'|" "${repo_config}"
    log_info "INFO: Traefik hashed password was updated in file ${repo_config}."
fi

# Version Control System (VCS) info on current repo --> Currently unused
# current_git_url=$(git config --get remote.origin.url)
# current_git_branch=$(git rev-parse --abbrev-ref HEAD)



# Generate WEBSERVER_SESSION_SECRET_KEY if the key is empty in repo_config
if [[ -z "${WEBSERVER_SESSION_SECRET_KEY}" ]]; then
    log_warning "INFO: Webserver session key is missing, creating one now."
    python3 -m pip install cryptography > /dev/null 2>&1
    WEBSERVER_SESSION_SECRET_KEY=$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key())" | sed -e '1s/^.//' ) # drops first char, i.e. 'b'
    $psed --in-place "s/WEBSERVER_SESSION_SECRET_KEY=.*/WEBSERVER_SESSION_SECRET_KEY=${WEBSERVER_SESSION_SECRET_KEY}/" "${repo_config}"
    set -o allexport
    # shellcheck disable=SC1090,SC1091
    source "${repo_config}"
    set +o allexport
fi

min_pw_length=8
if [ ${#SERVICES_PASSWORD} -lt $min_pw_length ]; then
    error_exit "Password length should be at least $min_pw_length characters"
fi
log_info "Deploying osparc for $1 cluster on ${MACHINE_FQDN}, using credentials $SERVICES_USER:$SERVICES_PASSWORD"


# -------------------------------- ASSERTIONS -------------------------------
if [ "$disable_vcs_check" -eq 1 ]; then
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

    # FIXME (DK): Add proper handling for when to (not) start minio
    # As of Oct2022, this should only be the case for vagrant/local.
    # Potentially, this can be done according to a S3_START_MINIO flag in the config?
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
        while [ ! "$(curl -s -o /dev/null -I -w "%{http_code}" --max-time 10 https://"${STORAGE_DOMAIN}"/minio/health/ready)" = 200 ]; do
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


    if [ "$stack_target" = "dalco" ] || [ "$stack_target" = "master" ] || [ "$stack_target" = "public" ]; then
    # -------------------------------- BACKUP PG -------------------------------
        log_info "starting PG-backup..."
        service_dir="${repo_basedir}"/services/pg-backup
        pushd "${service_dir}"
        call_make "." up-"$stack_target"
        popd
    fi


    if [ "$stack_target" = "aws" ] || [ "$stack_target" = "local" ]; then
        # -------------------------------- Mail -------------------------------
        log_info "starting mail server..."
        pushd "${repo_basedir}"/services/mail
        call_make "." up-"$stack_target"
        popd
    fi
    # -------------------------------- MONITORING -------------------------------

    log_info "starting monitoring..."
    # Pushd because a call with call_make trigger a strange behavior
    pushd "${repo_basedir}"/services/monitoring;
    call_make "." up-"$stack_target";
    popd

    # -------------------------------- ADMIN-PANELS -------------------------------

    log_info "starting admin-panels..."
    # Pushd because a call with call_make trigger a strange behavior
    pushd "${repo_basedir}"/services/admin-panels;
    call_make "." up-"$stack_target";
    popd

    # -------------------------------- GRAYLOG -------------------------------
    log_info "starting graylog..."
    service_dir="${repo_basedir}"/services/graylog
    pushd "${service_dir}"
    call_make "." up-"$stack_target"
    sleep 1
    call_make "." configure
    popd
fi
if [ "$start_simcore" -eq 0 ]; then
    if [ "$without_deploy_agent" -eq 0 ]; then
        log_info "starting simcore without deployment agent..."
        "${repo_basedir}"/scripts/deployments/start_without_deployment_agent.bash
    else
        # -------------------------------- DEPlOYMENT-AGENT -------------------------------
        log_info "starting deployment-agent for simcore..."
        pushd "${repo_basedir}"/services/deployment-agent;
        make down up-"$stack_target";
        popd
    fi
fi

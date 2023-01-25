#!/bin/bash
#
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
cd "$this_script_dir"
repo_basedir=$(git rev-parse --show-toplevel)
# shellcheck disable=1090,1091
source "$repo_basedir"/scripts/portable.sh
# Source bash logging tools
# shellcheck disable=1090,1091
source "$repo_basedir"/scripts/logger.bash
repo_config=$(cat "$repo_basedir"/.config.location)
#####################

#Defaults
devel_repo_path="0"
#

usage="$(basename "$0") [-h] [--key=value]

Deploys the simcore stack.

where keys are:
    -h, --help  show this help text
    --devel_repo_path             (default: ${devel_repo_path})"

for i in "$@"; do
    case $i in # Infos on bash case statements https://linuxize.com/post/bash-case-statement/
        --devel_repo_path=*)
        devel_repo_path="${i#*=}"
        ;;
        ##
        :|--help|-h)
        echo "$usage" && exit 0
        shift
        ;;
    esac
done
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
#
#
tempdirname=.temp
mkdir -p "$repo_basedir"/"$tempdirname"


###############
# IF NOT FLAG SET: SIMCORE DEVEL
if [[ "$devel_repo_path" = "0" ]] ; then
    log_info "Deploying osparc-simcore origin/master via github..."
    pushd "$tempdirname"
    #
    #       IF GETREPO DOESNT EXIST
    if [ ! -d osparc-simcore ]; then
        git clone "$GIT_SIMCORE_REPO_URL"
    fi
    #       FI
    #
    cd osparc-simcore
    git pull
    git checkout "$GIT_SIMCORE_REPO_BRANCH"
    cp services/docker-compose.yml "$repo_basedir"
else
    osparcsimcoredeveldir="$devel_repo_path"
    log_info "Deploying osparc-simcore local:development via local machine..."
    pushd "$osparcsimcoredeveldir"
    rm "$osparcsimcoredeveldir"/.env 2>/dev/null || true
    make build-devel
    # Create .env file:
    pushd "$repo_basedir"/services/simcore && make .env && cp .env "$osparcsimcoredeveldir"/.env && popd
    #
    export DOCKER_REGISTRY=local;
    export DOCKER_IMAGE_TAG=development;
    export DEV_PC_CPU_COUNT=8;
    # Download yq utility
    python -c "import urllib.request,os,sys,urllib; f = open(os.path.basename(sys.argv[1]), 'wb'); f.write(urllib.request.urlopen(sys.argv[1]).read()); f.close();" https://github.com/mikefarah/yq/releases/download/v4.29.2/yq_linux_amd64
    mv yq_linux_amd64 "$repo_basedir"/"$tempdirname"/yq
    chmod +x "$repo_basedir"/"$tempdirname"/yq
    _yq=$(realpath "$repo_basedir"/"$tempdirname"/yq)
    #
    # Mutate yaml

    $_yq "del(.services.traefik)" "$osparcsimcoredeveldir"/services/docker-compose.local.yml > "$repo_basedir"/"$tempdirname"/docker-compose.local.mutated.yml
    #
    docker-compose \
            --env-file "$repo_basedir"/services/simcore/.env \
            --file "$osparcsimcoredeveldir"/services/docker-compose.yml \
            --file "$repo_basedir"/"$tempdirname"/docker-compose.local.mutated.yml \
            --file "$osparcsimcoredeveldir"/services/docker-compose.devel.yml \
            --log-level=ERROR \
            config | sed --regexp-extended "s/cpus: ([0-9\\.]+)/cpus: '\\1'/" > "$osparcsimcoredeveldir"/.stack-simcore-development.yml
    # Ensures swarm is initialized
    # Ensures source-output folder always exists to avoid issues when mounting webclient->static-webserver dockers. Supports PowerShell
    mkdir -p "$osparcsimcoredeveldir"/services/static-webserver/client/source-output
    # Start compile+watch front-end container [front-end]
    make --no-print-directory --directory "$osparcsimcoredeveldir"/services/static-webserver/client down compile-dev flags=--watch
    # Mutate yaml
    $_yq "del(.services.postgres.ports)" "$osparcsimcoredeveldir"/.stack-simcore-development.yml > "$repo_basedir"/docker-compose.yml
fi
# FI

############
cp .env-devel "$repo_basedir"
cp .env-wb-garbage-collector "$repo_basedir"
############
popd
############
#
cp "$repo_config" "$repo_basedir"
#
cd "$repo_basedir"
rm -fr "$repo_basedir"/.temp
#
log_info "Creating stack.yml file..."
services/deployment-agent/startup_script.bash
log_info "Adding prefix $PREFIX_STACK_NAME to all services..."
./yq "with(.services; with_entries(.key |= \"${PREFIX_STACK_NAME}_\" + .))" stack.yml > stack_with_prefix.yml
log_info "Deleting the $SIMCORE_STACK_NAME docker stack if present"
docker stack rm "$SIMCORE_STACK_NAME" || true
sleep 3 # Wait for stack to be deleted, the networks often take a while, not waiting might lead to docker network creation issues
log_info "Deploying: Running docker stack deploy for stack $SIMCORE_STACK_NAME..."

# Retry logic via https://unix.stackexchange.com/a/82610
# shellcheck disable=2015
for i in {1..5}; do docker stack deploy -c stack_with_prefix.yml "$SIMCORE_STACK_NAME" && break || sleep 5; done


############
# CLEANUP
rm -r "${repo_basedir:?}"/"${tempdirname:?}" 2>/dev/null || true

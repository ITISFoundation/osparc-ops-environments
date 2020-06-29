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

function error_exit
{
    echo
    echo -e "\e[91m${1:-"Unknown Error"}" 1>&2
    exit 1
}

function substitute_environs
{
    # NOTE: be careful that no variable with $ are in .env or they will be replaced by envsubst unless a list of variables is given
       
    envsubst < "${1:-"Missing File"}" > "${2}"
}

function call_make
{
    make --no-print-directory --directory "${1:-"Missing Directory"}" "${2:-"Missing recipe"}"
}

# Using osx support functions
declare psed # fixes shellcheck issue with not finding psed
# shellcheck source=/dev/null
source "$( dirname "${BASH_SOURCE[0]}" )/../portable.sh"


# Paths
this_script_dir=$(dirname "$0")
repo_basedir=$(realpath "${this_script_dir}"/../../)

machine_ip=$(get_this_ip)

devel_mode=0
usage="$(basename "$0") [-h] [--key=value]

Deploys all the osparc-ops stacks and the SIM-core stack on osparc.local.

where keys are:
    -h, --help  show this help text
    --devel_mode             (default: ${devel_mode})"

for i in "$@"
do
case $i in
    --devel_mode=*)
    devel_mode="${i#*=}"
    shift # past argument=value
    ;;
    ##
    :|--help|-h|*)
    error_exit "$usage"
    ;;
esac
done

# Set local ip in repo.config
MANAGER_ENDPOINT_IP=${machine_ip}
export MANAGER_ENDPOINT_IP

# Loads configurations variables
# See https://askubuntu.com/questions/743493/best-way-to-read-a-config-file-in-bash
# shellcheck source=/dev/null
set -o allexport; source "${repo_basedir}"/repo.config; set +o allexport; 

min_pw_length=8
if [ ${#SERVICES_PASSWORD} -lt $min_pw_length ]; then
    error_exit "Password length should be at least $min_pw_length characters"
fi

echo
echo -e "\e[1;33mDeploying osparc on ${MACHINE_FQDN}, using credentials $SERVICES_USER:$SERVICES_PASSWORD...\e[0m"


# -------------------------------- PORTAINER ------------------------------
echo
echo -e "\e[1;33mstarting portainer...\e[0m"
call_make "${repo_basedir}"/services/portainer up

# -------------------------------- TRAEFIK -------------------------------
echo
echo -e "\e[1;33mstarting traefik...\e[0m"
# copy certificates to traefik
cp "${repo_basedir}"/certificates/*.crt "${repo_basedir}"/services/traefik/secrets/
cp "${repo_basedir}"/certificates/*.key "${repo_basedir}"/services/traefik/secrets/
call_make "${repo_basedir}"/services/traefik up-local

# -------------------------------- MINIO -------------------------------
# In the .env, MINIO_NUM_MINIOS and MINIO_NUM_PARTITIONS need to be set at 1 to work without labelling the nodes with minioX=true

echo
echo -e "\e[1;33mstarting minio...\e[0m"
service_dir="${repo_basedir}"/services/minio
call_make "${repo_basedir}"/services/minio up

echo "waiting for minio to run...don't worry..."
while [ ! "$(curl -s -o /dev/null -I -w "%{http_code}" --max-time 10 https://"${STORAGE_DOMAIN}"/minio/health/ready)" = 200 ]; do
    echo "waiting for minio to run..."
    sleep 5s
done

# -------------------------------- REGISTRY -------------------------------
echo
echo -e "\e[1;33mstarting registry...\e[0m"
call_make "${repo_basedir}"/services/registry up


# -------------------------------- Redis commander-------------------------------
echo
echo -e "\e[1;33mstarting redis commander...\e[0m"
call_make "${repo_basedir}"/services/redis-commander up

# -------------------------------- MONITORING -------------------------------
echo
echo -e "\e[1;33mstarting monitoring...\e[0m"
service_dir="${repo_basedir}"/services/monitoring
substitute_environs "${service_dir}"/grafana/template-config.monitoring "${service_dir}"/grafana/config.monitoring
substitute_environs "${service_dir}"/grafana/provisioning/datasources/datasource.yml.template "${service_dir}"/grafana/provisioning/datasources/datasource.yml
# if  the script is running under Windows, this line need to be commented : - /etc/hostname:/etc/host_hostname
if grep -qEi "(Microsoft|WSL)" /proc/version;
then 
    if [ ! "$(grep -qEi  "#- /etc/hostname:/etc/nodename # don't work with windows" &> /dev/null "${service_dir}"/docker-compose.yml)" ]
    then
        $psed --in-place --expression="s~- /etc/hostname:/etc/nodename # don't work with windows~#- /etc/hostname:/etc/nodename # don't work with windows~" "${service_dir}"/docker-compose.yml
    fi
else
    if [ "$(grep  "#- /etc/hostname:/etc/nodename # don't work with windows" &> /dev/null "${service_dir}"/docker-compose.yml)" ]  
    then
        $psed --in-place --expression="s~#- /etc/hostname:/etc/nodename # don't work with windows~- /etc/hostname:/etc/nodename # don't work with windows~" "${service_dir}"/docker-compose.yml
    fi
fi
call_make "${service_dir}" up
# -------------------------------- JAEGER -------------------------------
echo
echo -e "\e[1;33mstarting jaeger...\e[0m"
service_dir="${repo_basedir}"/services/jaeger
call_make "${service_dir}" up

# -------------------------------- Adminer -------------------------------
echo
echo -e "\e[1;33mstarting adminer...\e[0m"
service_dir="${repo_basedir}"/services/adminer
call_make "${service_dir}" up

# -------------------------------- GRAYLOG -------------------------------
echo
echo -e "\e[1;33mstarting graylog...\e[0m"
service_dir="${repo_basedir}"/services/graylog
# if  the script is running under Windows, this line need to be commented : - /etc/hostname:/etc/host_hostname
if grep -qEi "(Microsoft|WSL)" /proc/version;
then 
    if [ ! "$(grep -qEi  "#- /etc/hostname:/etc/host_hostname # does not work in windows" &> /dev/null "${service_dir}"/docker-compose.yml)" ]
    then
        $psed --in-place --expression="s~- /etc/hostname:/etc/host_hostname # does not work in windows~#- /etc/hostname:/etc/host_hostname # does not work in windows~" "${service_dir}"/docker-compose.yml
    fi
else
    if [ "$(grep  "#- /etc/hostname:/etc/host_hostname # does not work in windows" &> /dev/null "${service_dir}"/docker-compose.yml)" ]
    then
        $psed --in-place --expression="s~#- /etc/hostname:/etc/host_hostname # does not work in windows~- /etc/hostname:/etc/host_hostname # does not work in windows~" "${service_dir}"/docker-compose.yml
    fi
fi
call_make "${service_dir}" up
call_make "${service_dir}" configure-instance


if [ "$devel_mode" -eq 0 ]; then

    # -------------------------------- Simcore -------------------------------
    pushd "${repo_basedir}"/services/simcore;
    # VCS info on current repo
    current_git_url=$(git config --get remote.origin.url)
    current_git_branch=$(git rev-parse --abbrev-ref HEAD)

    simcore_env=".env"
    simcore_compose="docker-compose.deploy.yml"

    substitute_environs template${simcore_env} ${simcore_env}

    # docker-compose-simcore
    # for local use we need tls self-signed certificate for the traefik entrypoint in simcore
    $psed --in-place --expression='s/traefik.http.routers.${PREFIX_STACK_NAME}_webserver.entrypoints=.*/traefik.http.routers.${PREFIX_STACK_NAME}_webserver.entrypoints=https/' ${simcore_compose}
    $psed --in-place --expression='s/traefik.http.routers.${PREFIX_STACK_NAME}_webserver.tls=.*/traefik.http.routers.${PREFIX_STACK_NAME}_webserver.tls=true/' ${simcore_compose}

    # for local use we need to provide the generated certificate authority so that storage can access S3, or the director the registry
    $psed --in-place --expression='s/\s\s\s\s#secrets:/    secrets:/' ${simcore_compose}
    $psed --in-place --expression='s/\s\s\s\s\s\s#- source: rootca.crt/      - source: rootca.crt/' ${simcore_compose}
    $psed --in-place --expression="s~\s\s\s\s\s\s\s\s#target: /usr/local/share/ca-certificates/osparc.crt~        target: /usr/local/share/ca-certificates/osparc.crt~" ${simcore_compose}
    $psed --in-place --expression='s~\s\s\s\s\s\s#- SSL_CERT_FILE=/usr/local/share/ca-certificates/osparc.crt~      - SSL_CERT_FILE=/usr/local/share/ca-certificates/osparc.crt~' ${simcore_compose}



    # -------------------------------- DEPlOYMENT-AGENT -------------------------------
    echo
    echo -e "\e[1;33mstarting deployment-agent for simcore...\e[0m"
    pushd "${repo_basedir}"/services/deployment-agent;

    if [[ $current_git_url == git* ]]; then
        # it is a ssh style link let's get the organisation name and just replace this cause that conf only accepts https git repos
        current_organisation=$(echo "$current_git_url" | cut -d":" -f2 | cut -d"/" -f1)
        $psed --in-place "s|https://github.com/ITISFoundation/osparc-ops.git|https://github.com/$current_organisation/osparc-ops.git|" deployment_config.default.yaml
    else
        $psed --in-place "/- id: simcore-ops-repo/{n;s|url:.*|url: $current_git_url|}" deployment_config.default.yaml
    fi
    $psed --in-place "/- id: simcore-ops-repo/{n;n;s|branch:.*|branch: $current_git_branch|}" deployment_config.default.yaml

    secret_id=$(docker secret inspect --format="{{ .ID  }}" rootca.crt)
    # full original -> replacement
    YAML_STRING="environment:\n        S3_ENDPOINT: ${STORAGE_DOMAIN}:10000\n        S3_ACCESS_KEY: ${SERVICES_PASSWORD}\n        S3_SECRET_KEY: ${SERVICES_PASSWORD}"
    $psed --in-place "s/environment: {}/$YAML_STRING/" deployment_config.default.yaml
    # update
    $psed --in-place "s/S3_ENDPOINT:.*/S3_ENDPOINT: ${STORAGE_DOMAIN}/" deployment_config.default.yaml
    $psed --in-place "s/S3_ACCESS_KEY:.*/S3_ACCESS_KEY: ${SERVICES_PASSWORD}/" deployment_config.default.yaml
    $psed --in-place "s/S3_SECRET_KEY:.*/S3_SECRET_KEY: ${SERVICES_PASSWORD}/" deployment_config.default.yaml
    $psed --in-place "s/DIRECTOR_SELF_SIGNED_SSL_SECRET_ID:.*/DIRECTOR_SELF_SIGNED_SSL_SECRET_ID: ${secret_id}/" deployment_config.default.yaml
    # portainer
    $psed --in-place "/- url: .*portainer:9000/{n;s/username:.*/username: ${SERVICES_USER}/}" deployment_config.default.yaml
    $psed --in-place "/- url: .*portainer:9000/{n;n;s/password:.*/password: ${SERVICES_PASSWORD}/}" deployment_config.default.yaml
    # extra_hosts
    $psed --in-place "s|extra_hosts: \[\]|extra_hosts:\n        - \"${MACHINE_FQDN}:${machine_ip}\"|" deployment_config.default.yaml
    # AWS don't use Minio and Postgresql. We need to use them again in local.
    $psed --in-place "s~excluded_services:.*~excluded_services: [webclient]~" deployment_config.default.yaml
    # update
    $psed --in-place "/extra_hosts:/{n;s/- .*/- \"${MACHINE_FQDN}:${machine_ip}\"/}" deployment_config.default.yaml
    make down up;
    popd
fi



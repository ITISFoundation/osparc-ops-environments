#!/bin/bash
#
# Deploys in local host
#
#



# Using osx support functions
# shellcheck source=/dev/null
source "$( dirname "${BASH_SOURCE[0]}" )/portable.sh"
# ${psed:?}
set -euo pipefail
IFS=$'\n\t'
# Are we using WSL ?
grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null
is_WSL=$?

# Paths
this_script_dir=$(dirname "$0")
repo_basedir=$(realpath "${this_script_dir}"/../)
scripts_dir=$(realpath ${repo_basedir}/scripts)

# VCS info on current repo
current_git_url=$(git config --get remote.origin.url)
current_git_branch=$(git rev-parse --abbrev-ref HEAD)

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
    echo "$usage" >&2
    exit 1
    ;;
esac
done

# Loads configurations variables
# See https://askubuntu.com/questions/743493/best-way-to-read-a-config-file-in-bash
source "${repo_basedir}"/repo.config

min_pw_length=8
if [ ${#SERVICES_PASSWORD} -lt $min_pw_length ]; then
    echo "Password length should be at least $min_pw_length characters"
fi

cd "$repo_basedir";

echo
echo -e "\e[1;33mDeploying osparc on ${MACHINE_FQDN}, using credentials $SERVICES_USER:$SERVICES_PASSWORD...\e[0m"

# -------------------------------- Simcore -------------------------------

pushd ${repo_basedir}/services/simcore;

# Set the image tag to be used from dockerhub
$psed -i -e "s/DOCKER_IMAGE_TAG=.*/DOCKER_IMAGE_TAG=.$SIMCORE_IMAGE_TAG/" .env

# Hostnames
$psed -i -e "s/MONITORING_DOMAIN=.*/MONITORING_DOMAIN=.$MACHINE_FQDN/" .env
$psed -i -e "s/PUBLISHED_HOST_NAME=.*/PUBLISHED_HOST_NAME=$MACHINE_FQDN/" .env

# PGSQL
$psed -i -e "s/POSTGRES_DB=.*/POSTGRES_DB=$POSTGRES_DB/" .env
$psed -i -e "s/POSTGRES_ENDPOINT=.*/POSTGRES_ENDPOINT=$POSTGRES_ENDPOINT/" .env
$psed -i -e "s/POSTGRES_HOST=.*/POSTGRES_HOST=$POSTGRES_HOST/" .env
$psed -i -e "s/POSTGRES_USER=.*/POSTGRES_USER=$POSTGRES_USER/" .env
$psed -i -e "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$POSTGRES_PASSWORD/" .env
$psed -i -e "s/POSTGRES_PORT=.*/POSTGRES_PORT=$POSTGRES_PORT/" .env

# Registry
$psed -i -e "s/REGISTRY_AUTH=.*/REGISTRY_AUTH=$REGISTRY_AUTH/" .env
$psed -i -e "s/REGISTRY_PW=.*/REGISTRY_PW=$REGISTRY_PW/" .env
$psed -i -e "s/REGISTRY_SSL=.*/REGISTRY_SSL=$REGISTRY_SSL/" .env
$psed -i -e "s/REGISTRY_URL=.*/REGISTRY_URL=$REGISTRY_DOMAIN/" .env
$psed -i -e "s/REGISTRY_USER=.*/REGISTRY_USER=$REGISTRY_USER/" .env

# S3
$psed -i -e "s/S3_ACCESS_KEY=.*/S3_ACCESS_KEY=$SERVICES_PASSWORD/" .env
$psed -i -e "s/S3_SECRET_KEY=.*/S3_SECRET_KEY=$SERVICES_PASSWORD/" .env
$psed -i -e "s/S3_BUCKET_NAME=.*/S3_BUCKET_NAME=$S3_BUCKET/" .env
$psed -i -e "s/S3_ENDPOINT=.*/S3_ENDPOINT=$S3_ENDPOINT/" .env
$psed -i -e "s/S3_SECURE=.*/S3_SECURE=$S3_SECURE/" .env


# Mail
$psed -i -e "s/SMTP_HOST=.*/SMTP_HOST=$SMTP_HOST/" .env
$psed -i -e "s/SMTP_PORT=.*/SMTP_PORT=$SMTP_PORT/" .env
$psed -i -e "s/SMTP_USERNAME=.*/SMTP_USERNAME=$SMTP_USERNAME/" .env
$psed -i -e "s/SMTP_PASSWORD=.*/SMTP_PASSWORD=$SMTP_PASSWORD/" .env

# Osparc config
$psed -i -e "s/WEBSERVER_LOGIN_REGISTRATION_CONFIRMATION_REQUIRED=.*/WEBSERVER_LOGIN_REGISTRATION_CONFIRMATION_REQUIRED=$WEBSERVER_LOGIN_REGISTRATION_CONFIRMATION_REQUIRED/" .env
$psed -i -e "s/WEBSERVER_LOGIN_REGISTRATION_INVITATION_REQUIRED=.*/WEBSERVER_LOGIN_REGISTRATION_INVITATION_REQUIRED=$WEBSERVER_LOGIN_REGISTRATION_INVITATION_REQUIRED/" .env
$psed -i -e "s/WEBSERVER_STUDIES_ACCESS_ENABLED=.*/WEBSERVER_STUDIES_ACCESS_ENABLED=$WEBSERVER_STUDIES_ACCESS_ENABLED/" .env

# Rabbit
$psed -i -e "s/RABBIT_PORT=.*/RABBIT_PORT=$RABBIT_PORT/" .env
$psed -i -e "s/RABBIT_HOST=.*/RABBIT_HOST=$RABBIT_HOST/" .env
$psed -i -e "s/RABBIT_LOG_CHANNEL=.*/RABBIT_LOG_CHANNEL=$RABBIT_LOG_CHANNEL/" .env
$psed -i -e "s/RABBIT_PROGRESS_CHANNEL=.*/RABBIT_PROGRESS_CHANNEL=$RABBIT_PROGRESS_CHANNEL/" .env
$psed -i -e "s/RABBIT_USER=.*/RABBIT_USER=$RABBIT_USER/" .env
$psed -i -e "s/RABBIT_PASSWORD=.*/RRABBIT_PASSWORD=$RABBIT_PASSWORD/" .env

# Reddis
$psed -i -e "s/REDIS_HOST=.*/REDIS_HOST=$REDIS_HOST/" .env
$psed -i -e "s/REDIS_PORT=.*/REDIS_PORT=$REDIS_PORT/" .env


# docker-compose-simcore
$psed -i -e 's/traefik.http.routers.${PREFIX_STACK_NAME}_webserver.entrypoints=.*/traefik.http.routers.${PREFIX_STACK_NAME}_webserver.entrypoints=https/' docker-compose.deploy.yml
$psed -i -e 's/traefik.http.routers.${PREFIX_STACK_NAME}_webserver.tls=.*/traefik.http.routers.${PREFIX_STACK_NAME}_webserver.tls=true/' docker-compose.deploy.yml


# We use a auto-generated root certificate for storage
$psed -i -e 's/\s\s\s\s#secrets:/    secrets:/' docker-compose.deploy.yml
$psed -i -e 's/\s\s\s\s\s\s#- source: rootca.crt/      - source: rootca.crt/' docker-compose.deploy.yml
$psed -i -e "s~\s\s\s\s\s\s\s\s#target: /usr/local/share/ca-certificates/osparc.crt~        target: /usr/local/share/ca-certificates/osparc.crt~" docker-compose.deploy.yml
$psed -i -e 's~\s\s\s\s\s\s#- SSL_CERT_FILE=/usr/local/share/ca-certificates/osparc.crt~      - SSL_CERT_FILE=/usr/local/share/ca-certificates/osparc.crt~' docker-compose.deploy.yml

popd


# -------------------------------- PORTAINER ------------------------------
echo
echo -e "\e[1;33mstarting portainer...\e[0m"
pushd "${repo_basedir}"/services/portainer
sed -i "s/PORTAINER_ADMIN_PWD=.*/PORTAINER_ADMIN_PWD=$SERVICES_PASSWORD/" .env
sed -i "s/MACHINE_FQDN=.*/MACHINE_FQDN=$MACHINE_FQDN/" .env
make up
popd

# -------------------------------- TRAEFIK -------------------------------
echo
echo -e "\e[1;33mstarting traefik...\e[0m"
pushd "${repo_basedir}"/services/traefik
# copy certificates to traefik
cp "${repo_basedir}"/certificates/*.crt secrets/
cp "${repo_basedir}"/certificates/*.key secrets/
# setup configuration
$psed -i -e "s/MACHINE_FQDN=.*/MACHINE_FQDN=$MACHINE_FQDN/" .env
$psed -i -e "s/MONITORING_DOMAIN=.*/MONITORING_DOMAIN=$MONITORING_DOMAIN/" .env
$psed -i -e "s/TRAEFIK_USER=.*/TRAEFIK_USER=$SERVICES_USER/" .env
traefik_password=$(docker run --rm --entrypoint htpasswd registry:2 -nb "$SERVICES_USER" "$SERVICES_PASSWORD" | cut -d ':' -f2)
$psed -i -e "s|TRAEFIK_PASSWORD=.*|TRAEFIK_PASSWORD=${traefik_password}|" .env
make up-local
popd

# -------------------------------- MINIO -------------------------------
# In the .env, MINIO_NUM_MINIOS and MINIO_NUM_PARTITIONS need to be set at 1 to work without labelling the nodes with minioX=true

echo
echo -e "\e[1;33mstarting minio...\e[0m"
pushd "${repo_basedir}"/services/minio;
$psed -i -e "s/MINIO_NUM_MINIOS=.*/MINIO_NUM_MINIOS=1/" .env
$psed -i -e "s/MINIO_NUM_PARTITIONS=.*/MINIO_NUM_PARTITIONS=1/" .env

$psed -i -e "s/MINIO_ACCESS_KEY=.*/MINIO_ACCESS_KEY=$SERVICES_PASSWORD/" .env
$psed -i -e "s/MINIO_SECRET_KEY=.*/MINIO_SECRET_KEY=$SERVICES_PASSWORD/" .env
$psed -i -e "s/STORAGE_DOMAIN=.*/STORAGE_DOMAIN=${STORAGE_DOMAIN}/" .env
make up; popd
echo "waiting for minio to run...don't worry..."
while [ ! "$(curl -s -o /dev/null -I -w "%{http_code}" --max-time 10 https://"${STORAGE_DOMAIN}"/minio/health/ready)" = 200 ]; do
    echo "waiting for minio to run..."
    sleep 5s
done

# -------------------------------- REGISTRY -------------------------------
echo
echo -e "\e[1;33mstarting registry...\e[0m"
pushd ${repo_basedir}/services/registry

# set configuration
$psed -i -e "s/REGISTRY_DOMAIN=.*/REGISTRY_DOMAIN=$REGISTRY_DOMAIN/" .env
$psed -i -e "s/S3_ACCESS_KEY_ID=.*/S3_ACCESS_KEY_ID=$SERVICES_PASSWORD/" .env
$psed -i -e "s/S3_SECRET_ACCESS_KEY=.*/S3_SECRET_ACCESS_KEY=$SERVICES_PASSWORD/" .env
$psed -i -e "s/S3_BUCKET=.*/S3_BUCKET=${S3_BUCKET}/" .env
$psed -i -e "s/S3_ENDPOINT=.*/S3_ENDPOINT=${S3_ENDPOINT}/" .env
make up
popd

# -------------------------------- MONITORING -------------------------------
echo
echo -e "\e[1;33mstarting monitoring...\e[0m"
# set MACHINE_FQDN
pushd "${repo_basedir}"/services/monitoring
$psed -i -e "s/MONITORING_DOMAIN=.*/MONITORING_DOMAIN=$MONITORING_DOMAIN/" .env
$psed -i -e "s|GF_SERVER_ROOT_URL=.*|GF_SERVER_ROOT_URL=https://$MACHINE_FQDN/grafana|" grafana/config.monitoring
$psed -i -e "s|GF_SECURITY_ADMIN_PASSWORD=.*|GF_SECURITY_ADMIN_PASSWORD=$SERVICES_PASSWORD|" grafana/config.monitoring
$psed -i -e "s|basicAuthPassword:.*|basicAuthPassword: $SERVICES_PASSWORD|" grafana/provisioning/datasources/datasource.yml

# if  WSL, we comment - /etc/hostname:/etc/host_hostname
if [ is_WSL ] 
then 
    if [ ! $(grep -qEi  "#- /etc/hostname:/etc/nodename # don't work with windows" &> /dev/null docker-compose.yml) ]
    then
        $psed -i -e "s~- /etc/hostname:/etc/nodename # don't work with windows~#- /etc/hostname:/etc/nodename # don't work with windows~" docker-compose.yml
    fi
else
    if [ $(grep  "#- /etc/hostname:/etc/nodename # don't work with windows" &> /dev/null docker-compose.yml) ]  
    then
        $psed -i -e "s~#- /etc/hostname:/etc/nodename # don't work with windows~- /etc/hostname:/etc/nodename # don't work with windows~" docker-compose.yml
    fi
fi

make up
popd

# -------------------------------- JAEGER -------------------------------
echo
echo -e "\e[1;33mstarting jaeger...\e[0m"
# set MACHINE_FQDN
pushd "${repo_basedir}"/services/jaeger
$psed -i -e "s/MONITORING_DOMAIN=.*/MONITORING_DOMAIN=$MONITORING_DOMAIN/" .env
make up
popd


# -------------------------------- Adminer -------------------------------
echo
echo -e "\e[1;33mstarting adminer...\e[0m"
pushd ${repo_basedir}/services/adminer
$psed -i -e "s/MONITORING_DOMAIN=.*/MONITORING_DOMAIN=$MONITORING_DOMAIN/" .env
$psed -i -e "s/PG_HOST=.*/PG_HOST=$POSTGRES_ENDPOINT/" .env
make up
popd

# -------------------------------- GRAYLOG -------------------------------
echo
echo -e "\e[1;33mstarting graylog...\e[0m"
# set MACHINE_FQDN
pushd "${repo_basedir}"/services/graylog;
graylog_password=$(echo -n "$SERVICES_PASSWORD" | sha256sum | cut -d ' ' -f1)
$psed -i -e "s/MONITORING_DOMAIN=.*/MONITORING_DOMAIN=$MONITORING_DOMAIN/" .env
$psed -i -e "s|GRAYLOG_HTTP_EXTERNAL_URI=.*|GRAYLOG_HTTP_EXTERNAL_URI=https://$MONITORING_DOMAIN/graylog/|" .env
$psed -i -e "s|GRAYLOG_ROOT_PASSWORD_SHA2=.*|GRAYLOG_ROOT_PASSWORD_SHA2=$graylog_password|" .env

# if  WSL, we comment - /etc/hostname:/etc/host_hostname
if [ is_WSL ] 
then 
    if [ ! $(grep -qEi  "#- /etc/hostname:/etc/host_hostname # does not work in windows" &> /dev/null docker-compose.yml) ]
    then
        $psed -i -e "s~- /etc/hostname:/etc/host_hostname # does not work in windows~#- /etc/hostname:/etc/host_hostname # does not work in windows~" docker-compose.yml
    fi
else
    if [ $(grep  "#- /etc/hostname:/etc/host_hostname # does not work in windows" &> /dev/null docker-compose.yml) ]  
    then
        $psed -i -e "s~#- /etc/hostname:/etc/host_hostname # does not work in windows~- /etc/hostname:/etc/host_hostname # does not work in windows~" docker-compose.yml
    fi
fi

make up

echo
echo "waiting for graylog to run..."
while [ ! "$(curl -s -o /dev/null -I -w "%{http_code}" --max-time 10  -H "Accept: application/json" -H "Content-Type: application/json" -X GET https://"$MONITORING_DOMAIN"/graylog/api/users)" = 401 ]; do
    echo "waiting for graylog to run..."
    sleep 5s
done
json_data=$(cat <<EOF
{
"title": "standard GELF UDP input",
    "type": "org.graylog2.inputs.gelf.udp.GELFUDPInput",
    "global": "true",
    "configuration": {
        "bind_address": "0.0.0.0",
        "port":12201
    }
}
EOF
)
curl -u "$SERVICES_USER":"$SERVICES_PASSWORD" --header "Content-Type: application/json" \
    --header "X-Requested-By: cli" -X POST \
    --data "$json_data" https://"$MONITORING_DOMAIN"/graylog/api/system/inputs
popd

# -------------------------------- ADMINER -------------------------------
echo
echo -e "\e[1;33mstarting adminer...\e[0m"
pushd "${repo_basedir}"/services/adminer;
make up
popd

if [ $devel_mode -eq 0 ]; then

    # -------------------------------- DEPlOYMENT-AGENT -------------------------------
    echo
    echo -e "\e[1;33mstarting deployment-agent for simcore...\e[0m"
    pushd "${repo_basedir}"/services/deployment-agent;

    if [[ $current_git_url == git* ]]; then
        # it is a ssh style link let's get the organisation name and just replace this cause that conf only accepts https git repos
        current_organisation=$(echo "$current_git_url" | cut -d":" -f2 | cut -d"/" -f1)
        sed -i "s|https://github.com/ITISFoundation/osparc-ops.git|https://github.com/$current_organisation/osparc-ops.git|" deployment_config.default.yaml
    else
        sed -i "/- id: simcore-ops-repo/{n;s|url:.*|url: $current_git_url|}" deployment_config.default.yaml
    fi
    sed -i "/- id: simcore-ops-repo/{n;n;s|branch:.*|branch: $current_git_branch|}" deployment_config.default.yaml

    secret_id=$(docker secret inspect --format="{{ .ID  }}" rootca.crt)
    # full original -> replacement
    YAML_STRING="environment:\n        S3_ENDPOINT: ${STORAGE_DOMAIN}:10000\n        S3_ACCESS_KEY: ${SERVICES_PASSWORD}\n        S3_SECRET_KEY: ${SERVICES_PASSWORD}"
    sed -i "s/environment: {}/$YAML_STRING/" deployment_config.default.yaml
    # update
    sed -i "s/S3_ENDPOINT:.*/S3_ENDPOINT: ${STORAGE_DOMAIN}/" deployment_config.default.yaml
    sed -i "s/S3_ACCESS_KEY:.*/S3_ACCESS_KEY: ${SERVICES_PASSWORD}/" deployment_config.default.yaml
    sed -i "s/S3_SECRET_KEY:.*/S3_SECRET_KEY: ${SERVICES_PASSWORD}/" deployment_config.default.yaml
    sed -i "s/DIRECTOR_SELF_SIGNED_SSL_SECRET_ID:.*/DIRECTOR_SELF_SIGNED_SSL_SECRET_ID: ${secret_id}/" deployment_config.default.yaml
    # portainer
    sed -i "/- url: .*portainer:9000/{n;s/username:.*/username: ${SERVICES_USER}/}" deployment_config.default.yaml
    sed -i "/- url: .*portainer:9000/{n;n;s/password:.*/password: ${SERVICES_PASSWORD}/}" deployment_config.default.yaml
    # extra_hosts
    sed -i "s|extra_hosts: \[\]|extra_hosts:\n        - \"${MACHINE_FQDN}:${machine_ip}\"|" deployment_config.default.yaml
    # AWS don't use Minio and Postgresql. We need to use them again in local.
    sed -i "s~excluded_services:.*~excluded_services: [webclient]~" deployment_config.default.yaml
    # Prefix stack name
    $psed -i -e "s/PREFIX_STACK_NAME=.*/PREFIX_STACK_NAME=$PREFIX_STACK_NAME/" .env
    # defines the simcore stack name
    $psed -i -e "s/SIMCORE_STACK_NAME=.*/SIMCORE_STACK_NAME=$SIMCORE_STACK_NAME/" .env
    # set the image tag to be used from dockerhub
    $psed -i -e "s/SIMCORE_IMAGE_TAG=.*/SIMCORE_IMAGE_TAG=$SIMCORE_IMAGE_TAG/" .env
    # update
    sed -i "/extra_hosts:/{n;s/- .*/- \"${MACHINE_FQDN}:${machine_ip}\"/}" deployment_config.default.yaml
    make down up;
    popd
fi

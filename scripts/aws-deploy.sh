#!/bin/bash
#
# Deploy the stack within AWS. The script take the FQDN values (FQDN and monitoring FQDN) from the repo.config file and edit each.env files
#
#

set -euo pipefail
IFS=$'\n\t'

# Using osx support functions
source "$( dirname "${BASH_SOURCE[0]}" )/portable.sh"

# Paths
this_script_dir=$(dirname "$0")
repo_basedir=$(realpath ${this_script_dir}/../)

# VCS info on current repo
current_git_url=$(git config --get remote.origin.url)
current_git_branch=$(git rev-parse --abbrev-ref HEAD)


# Loads configurations variables
# See https://askubuntu.com/questions/743493/best-way-to-read-a-config-file-in-bash
source ${repo_basedir}/repo.config

# Mails host and login/password

echo $SMTP_HOST | grep -Eo "([^.*.*]+)"

# -------------------------------- Simcore -------------------------------

pushd ${repo_basedir}/services/simcore;

ori_env_simcore=`cat .env`

# Set the image tag to be used from dockerhub
$psed -i -e "s/DOCKER_IMAGE_TAG=.*/DOCKER_IMAGE_TAG=$SIMCORE_IMAGE_TAG/" .env

# Hostnames
$psed -i -e "s/MONITORING_DOMAIN=.*/MONITORING_DOMAIN=$MONITORING_DOMAIN/" .env
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
$psed -i -e "s/S3_ACCESS_KEY=.*/S3_ACCESS_KEY=$ACCESS_KEY_ID/" .env
$psed -i -e "s~S3_SECRET_KEY=.*~S3_SECRET_KEY=$SECRET_ACCESS_KEY~" .env
$psed -i -e "s/S3_BUCKET_NAME=.*/S3_BUCKET_NAME=$S3_BUCKET/" .env
$psed -i -e "s/S3_ENDPOINT=.*/S3_ENDPOINT=$S3_ENDPOINT/" .env
$psed -i -e "s/S3_SECURE=.*/S3_SECURE=$S3_SECURE/" .env

# mail
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
ori_compose_simcore=`cat docker-compose.deploy.yml`

# Traefik does not use https
$psed -i -e 's/traefik.http.routers.${PREFIX_STACK_NAME}_webserver.entrypoints=.*/traefik.http.routers.${PREFIX_STACK_NAME}_webserver.entrypoints=http/' docker-compose.deploy.yml
$psed -i -e 's/traefik.http.routers.${PREFIX_STACK_NAME}_webserver.tls=.*/traefik.http.routers.${PREFIX_STACK_NAME}_webserver.tls=false/' docker-compose.deploy.yml

# We don't use a auto-generated root certificate for storage
$psed -i -e 's/\s\s\s\ssecrets:/    #secrets:/' docker-compose.deploy.yml
$psed -i -e 's/\s\s\s\s\s\s- source: rootca.crt/      #- source: rootca.crt/' docker-compose.deploy.yml
$psed -i -e "s~\s\s\s\s\s\s\s\starget: /usr/local/share/ca-certificates/osparc.crt~        #target: /usr/local/share/ca-certificates/osparc.crt~" docker-compose.deploy.yml
$psed -i -e 's~\s\s\s\s\s\s- SSL_CERT_FILE=/usr/local/share/ca-certificates/osparc.crt~      #- SSL_CERT_FILE=/usr/local/share/ca-certificates/osparc.crt~' docker-compose.deploy.yml

new_compose_simcore=`cat docker-compose.deploy.yml`
new_env_simcore=`cat .env`
if [ "$ori_env_simcore" = "$new_env_simcore" ] && [ "$ori_compose_simcore" = "$new_compose_simcore" ]; then
    echo "Simcore service ready for deployment"
else
    echo "Some values weren't up to to date in Simcore service (.env and/or docker-compose.deploy). They have been updated, please push them to github and restart the script"
    exit
fi

popd


# -------------------------------- PORTAINER ------------------------------
echo
echo -e "\e[1;33mstarting portainer...\e[0m"
pushd ${repo_basedir}/services/portainer
$psed -i -e "s/MACHINE_FQDN=.*/MACHINE_FQDN=$MACHINE_FQDN/" .env
$psed -i -e "s/MONITORING_DOMAIN=.*/MONITORING_DOMAIN=$MONITORING_DOMAIN/" .env
make up-aws
popd



# -------------------------------- TRAEFIK -------------------------------
echo
echo -e "\e[1;33mstarting traefik...\e[0m"
pushd ${repo_basedir}/services/traefik
$psed -i -e "s/MONITORING_DOMAIN=.*/MONITORING_DOMAIN=$MONITORING_DOMAIN/" .env
$psed -i -e "s/MACHINE_FQDN=.*/MACHINE_FQDN=$MACHINE_FQDN/" .env
make up-aws
popd



# -------------------------------- REGISTRY -------------------------------
echo
echo -e "\e[1;33mstarting registry...\e[0m"
pushd ${repo_basedir}/services/registry
$psed -i -e "s/REGISTRY_DOMAIN=.*/REGISTRY_DOMAIN=$REGISTRY_DOMAIN/" .env
$psed -i -e "s/S3_ACCESS_KEY_ID=.*/S3_ACCESS_KEY_ID=$REGISTRY_S3_ACCESS_KEY_ID/" .env
$psed -i -e "s~S3_SECRET_ACCESS_KEY=.*~S3_SECRET_ACCESS_KEY=$REGISTRY_S3_SECRET_ACCESS_KEY~" .env
$psed -i -e "s/S3_BUCKET=.*/S3_BUCKET=$REGISTRY_S3_BUCKET/" .env
$psed -i -e "s/S3_ENDPOINT=.*/S3_ENDPOINT=$REGISTRY_S3_ENDPOINT/" .env
$psed -i -e "s/S3_SECURE=.*/S3_SECURE=$REGISTRY_S3_SECURE/" .env
$psed -i -e "s/AWS_REGION=.*/AWS_REGION=$REGISTRY_AWS_REGION/" .env
make up-aws
popd



# -------------------------------- MONITORING -------------------------------

echo
echo -e "\e[1;33mstarting monitoring...\e[0m"

# grafana config
pushd ${repo_basedir}/services/monitoring/grafana

$psed -i -e "s/GF_SERVER_DOMAIN=.*/GF_SERVER_DOMAIN=$MONITORING_DOMAIN/"  config.monitoring
$psed -i -e "s~GF_SERVER_ROOT_URL=.*~GF_SERVER_ROOT_URL=https://$MONITORING_DOMAIN/grafana~"  config.monitoring
popd

# monitoring config
pushd ${repo_basedir}/services/monitoring
# if  WSL, we comment - /etc/hostname:/etc/host_hostname

if grep -qF  "#- /etc/hostname:/etc/nodename # don't work with windows" docker-compose.yml
then
    echo "Changing /etc/hostname in Monitoring configuration"
    $psed -i -e "s~#- /etc/hostname:/etc/nodename # don't work with windows~- /etc/hostname:/etc/nodename # don't work with windows~" docker-compose.yml
fi

$psed -i -e "s/MONITORING_DOMAIN=.*/MONITORING_DOMAIN=$MONITORING_DOMAIN/" .env
make up-aws
popd


# -------------------------------- JAEGER -------------------------------
echo
echo -e "\e[1;33mstarting jaeger...\e[0m"
pushd ${repo_basedir}/services/jaeger
$psed -i -e "s/MONITORING_DOMAIN=.*/MONITORING_DOMAIN=$MONITORING_DOMAIN/" .env
make up-aws
popd

# -------------------------------- Adminer -------------------------------
echo
echo -e "\e[1;33mstarting adminer...\e[0m"
pushd ${repo_basedir}/services/adminer
$psed -i -e "s/MONITORING_DOMAIN=.*/MONITORING_DOMAIN=$MONITORING_DOMAIN/" .env
$psed -i -e "s/PG_HOST=.*/PG_HOST=$POSTGRES_ENDPOINT/" .env
make up-aws
popd

# -------------------------------- Mail -------------------------------
echo
echo -e "\e[1;33mstarting mail server...\e[0m"
pushd ${repo_basedir}/services/mail



$psed -i -e "s/MONITORING_DOMAIN=.*/MONITORING_DOMAIN=$SMTP_HOST/" .env
$psed -i -e "s/PG_HOST=.*/PG_HOST=$POSTGRES_ENDPOINT/" .env
#./setup.sh email add support@simcore.io alexamdre



make up-aws
popd


# -------------------------------- GRAYLOG -------------------------------
echo
echo -e "\e[1;33mstarting graylog...\e[0m"

pushd ${repo_basedir}/services/graylog;

# Uncomment - /etc/hostname:/etc/host_hostname - In local for WSL, the script for the local deployement commment it automatically

if grep -qF  "#- /etc/hostname:/etc/host_hostname # does not work in windows" docker-compose.yml
then
    echo "Changing /etc/hostname in Graylog configuration"
    $psed -i -e "s~#- /etc/hostname:/etc/host_hostname # does not work in windows~- /etc/hostname:/etc/host_hostname # does not work in windows~" docker-compose.yml
fi


$psed -i -e "s/MONITORING_DOMAIN=.*/MONITORING_DOMAIN=$MONITORING_DOMAIN/" .env
$psed -i -e "s~GRAYLOG_HTTP_EXTERNAL_URI=.*~GRAYLOG_HTTP_EXTERNAL_URI=https://$MONITORING_DOMAIN/graylog/~" .env
make up-aws

# Wait for Graylog to start, then send a request configuring one INPUT to allow graylogs to receive logs transmitted by LOGSPOUT
echo
echo "waiting for graylog to run..."
while [ ! $(curl -s -o /dev/null -I -w "%{http_code}" --max-time 10 -H "Accept: application/json" -H "Content-Type: application/json" -X GET https://$MONITORING_DOMAIN/graylog/api/users) = 401 ]; do
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
curl -u $GRAYLOG_LOGIN:$GRAYLOG_ROOT_PASSWORD --header "Content-Type: application/json" \
    --header "X-Requested-By: cli" -X POST \
    --data "$json_data" https://$MONITORING_DOMAIN/graylog/api/system/inputs
popd



# -------------------------------- DEPlOYMENT-AGENT -------------------------------
echo
echo -e "\e[1;33mstarting deployment-agent for simcore...\e[0m"
pushd ${repo_basedir}/services/deployment-agent;
if [[ $current_git_url == git* ]]; then
    # it is a ssh style link let's get the organisation name and just replace this cause that conf only accepts https git repos
    current_organisation=$(echo $current_git_url | cut -d":" -f2 | cut -d"/" -f1)
    sed -i "s|https://github.com/ITISFoundation/osparc-ops.git|https://github.com/$current_organisation/osparc-ops.git|" deployment_config.default.yaml
else
    sed -i "/- id: simcore-ops-repo/{n;s|url:.*|url: $current_git_url|}" deployment_config.default.yaml
fi
sed -i "/- id: simcore-ops-repo/{n;n;s|branch:.*|branch: $current_git_branch|}" deployment_config.default.yaml

# Add environment variable that will be used by the simcore stack when deployed with the deployement-agent
YAML_STRING="environment:\n        S3_ENDPOINT: ${S3_ENDPOINT}\n        S3_ACCESS_KEY: ${ACCESS_KEY_ID}\n        S3_SECRET_KEY: ${SECRET_ACCESS_KEY}"
sed -i "s~environment: {}~$YAML_STRING~" deployment_config.default.yaml
# update in case there is already something in "environment: {}"
sed -i "s/S3_ENDPOINT:.*/S3_ENDPOINT: ${S3_ENDPOINT}/" deployment_config.default.yaml
sed -i "s~S3_ACCESS_KEY:.*~S3_ACCESS_KEY: ${ACCESS_KEY_ID}~" deployment_config.default.yaml
sed -i "s~S3_SECRET_KEY:.*~S3_SECRET_KEY: ${SECRET_ACCESS_KEY}~" deployment_config.default.yaml

# We don't use Minio and postgresql with AWS
sed -i "s~excluded_services:.*~excluded_services: [webclient, minio, postgres]~" deployment_config.default.yaml
# Prefix stack name
$psed -i -e "s/PREFIX_STACK_NAME=.*/PREFIX_STACK_NAME=$PREFIX_STACK_NAME/" .env
# defines the simcore stack name
$psed -i -e "s/SIMCORE_STACK_NAME=.*/SIMCORE_STACK_NAME=$SIMCORE_STACK_NAME/" .env
# set the image tag to be used from dockerhub
$psed -i -e "s/SIMCORE_IMAGE_TAG=.*/SIMCORE_IMAGE_TAG=$SIMCORE_IMAGE_TAG/" .env
make down up-aws;
popd
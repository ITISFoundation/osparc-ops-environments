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

# Paths
this_script_dir=$(dirname "$0")
repo_basedir=$(realpath "${this_script_dir}"/../)

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


# -------------------------------- PORTAINER ------------------------------
echo
echo -e "\e[1;33mstarting portainer...\e[0m"
pushd "${repo_basedir}"/services/portainer
sed -i "s/PORTAINER_ADMIN_PWD=.*/PORTAINER_ADMIN_PWD=$SERVICES_PASSWORD/" .env
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
$psed -i -e "s/TRAEFIK_USER=.*/TRAEFIK_USER=$SERVICES_USER/" .env
traefik_password=$(docker run --rm --entrypoint htpasswd registry:2 -nb "$SERVICES_USER" "$SERVICES_PASSWORD" | cut -d ':' -f2)
$psed -i -e "s|TRAEFIK_PASSWORD=.*|TRAEFIK_PASSWORD=${traefik_password}|" .env
make up-local
popd

# -------------------------------- MINIO -------------------------------
echo
echo -e "\e[1;33mstarting minio...\e[0m"
pushd "${repo_basedir}"/services/minio;
$psed -i -e "s/MINIO_ACCESS_KEY=.*/MINIO_ACCESS_KEY=$SERVICES_PASSWORD/" .env
$psed -i -e "s/MINIO_SECRET_KEY=.*/MINIO_SECRET_KEY=$SERVICES_PASSWORD/" .env
make up; popd
echo "waiting for minio to run...don't worry..."
while [ ! "$(curl -s -o /dev/null -I -w "%{http_code}" --max-time 10 https://"${MACHINE_FQDN}":10000/minio/health/ready)" = 200 ]; do
    echo "waiting for minio to run..."
    sleep 5s
done

# -------------------------------- PORTUS/REGISTRY -------------------------------
echo
echo -e "\e[1;33mstarting portus/registry...\e[0m"
pushd "${repo_basedir}"/services/portus
# copy certificates to portus
cp -u "${repo_basedir}"/certificates/domain.crt secrets/portus.crt
cp -u "${repo_basedir}"/certificates/domain.key secrets/portus.key
cp -u "${repo_basedir}"/certificates/rootca.crt secrets/rootca.crt

# set configuration
$psed -i -e "s/MACHINE_FQDN=.*/MACHINE_FQDN=$MACHINE_FQDN/" .env
$psed -i -e "s/S3_ACCESSKEY=.*/S3_ACCESSKEY=$SERVICES_PASSWORD/" .env
$psed -i -e "s/S3_SECRETKEY=.*/S3_SECRETKEY=$SERVICES_PASSWORD/" .env
make up-self-signed

# auto configure portus
echo
echo "waiting for portus to run...don't worry..."
while [ ! "$(curl -s -o /dev/null -I -w "%{http_code}" --max-time 10 -H "Accept: application/json" -H "Content-Type: application/json" -X GET https://"${MACHINE_FQDN}":5000/api/v1/users)" = 401 ]; do
    echo "waiting for portus to run..."
    sleep 5s
done

if [ ! -f .portus_token ]; then
    echo
    echo "configuring portus via its API ..."
json_data=$(cat <<EOF
{
    "user": {
        "username": "$SERVICES_USER",
        "email": "admin@swiss",
        "password": "$SERVICES_PASSWORD"
    }
}
EOF
)
    portus_token=$(curl -H "Accept: application/json" -H "Content-Type: application/json" -X POST \
        -d "${json_data}" https://"$MACHINE_FQDN":5000/api/v1/users/bootstrap | jq -r .plain_token)
    echo "${portus_token}" >> .portus_token

json_data=$(cat <<EOF
{
    "registry": {
        "name": "$MACHINE_FQDN",
        "hostname": "$MACHINE_FQDN:5000",
        "use_ssl": true
    }
}
EOF
)
    curl -H "Accept: application/json" -H "Content-Type: application/json" -H "Portus-Auth: $SERVICES_USER:${portus_token}"  -X POST \
        -d "${json_data}" https://"$MACHINE_FQDN":5000/api/v1/registries
fi
popd

# -------------------------------- MONITORING -------------------------------
echo
echo -e "\e[1;33mstarting monitoring...\e[0m"
# set MACHINE_FQDN
pushd "${repo_basedir}"/services/monitoring
$psed -i -e "s|GF_SERVER_ROOT_URL=.*|GF_SERVER_ROOT_URL=https://$MACHINE_FQDN/grafana|" grafana/config.monitoring
$psed -i -e "s|GF_SECURITY_ADMIN_PASSWORD=.*|GF_SECURITY_ADMIN_PASSWORD=$SERVICES_PASSWORD|" grafana/config.monitoring
$psed -i -e "s|basicAuthPassword:.*|basicAuthPassword: $SERVICES_PASSWORD|" grafana/provisioning/datasources/datasource.yml
$psed -i -e "s|--web.external-url=.*|--web.external-url=https://$MACHINE_FQDN/prometheus/'|" docker-compose.yml
make up
popd

# -------------------------------- JAEGER -------------------------------
echo
echo -e "\e[1;33mstarting jaeger...\e[0m"
# set MACHINE_FQDN
pushd "${repo_basedir}"/services/jaeger
make up
popd

# -------------------------------- GRAYLOG -------------------------------
echo
echo -e "\e[1;33mstarting graylog...\e[0m"
# set MACHINE_FQDN
pushd "${repo_basedir}"/services/graylog;
graylog_password=$(echo -n "$SERVICES_PASSWORD" | sha256sum | cut -d ' ' -f1)
$psed -i -e "s|GRAYLOG_HTTP_EXTERNAL_URI=.*|GRAYLOG_HTTP_EXTERNAL_URI=https://$MACHINE_FQDN/graylog/|" .env
$psed -i -e "s|GRAYLOG_ROOT_PASSWORD_SHA2=.*|GRAYLOG_ROOT_PASSWORD_SHA2=$graylog_password|" .env
make up

echo
echo "waiting for graylog to run..."
while [ ! "$(curl -s -o /dev/null -I -w "%{http_code}" --max-time 10 -H "Accept: application/json" -H "Content-Type: application/json" -X GET https://"$MACHINE_FQDN"/graylog/api/users)" = 401 ]; do
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
    --data "$json_data" https://"$MACHINE_FQDN"/graylog/api/system/inputs
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
    YAML_STRING="environment:\n        S3_ENDPOINT: ${MACHINE_FQDN}:10000\n        S3_ACCESS_KEY: ${SERVICES_PASSWORD}\n        S3_SECRET_KEY: ${SERVICES_PASSWORD}\n        DIRECTOR_SELF_SIGNED_SSL_SECRET_ID: ${secret_id}"
    sed -i "s/environment: {}/$YAML_STRING/" deployment_config.default.yaml
    # update
    sed -i "s/S3_ENDPOINT:.*/S3_ENDPOINT: ${MACHINE_FQDN}:10000/" deployment_config.default.yaml
    sed -i "s/S3_ACCESS_KEY:.*/S3_ACCESS_KEY: ${SERVICES_PASSWORD}/" deployment_config.default.yaml
    sed -i "s/S3_SECRET_KEY:.*/S3_SECRET_KEY: ${SERVICES_PASSWORD}/" deployment_config.default.yaml
    sed -i "s/DIRECTOR_SELF_SIGNED_SSL_SECRET_ID:.*/DIRECTOR_SELF_SIGNED_SSL_SECRET_ID: ${secret_id}/" deployment_config.default.yaml
    # portainer
    sed -i "/- url: .*portainer:9000/{n;s/username:.*/username: ${SERVICES_USER}/}" deployment_config.default.yaml
    sed -i "/- url: .*portainer:9000/{n;n;s/password:.*/password: ${SERVICES_PASSWORD}/}" deployment_config.default.yaml
    # extra_hosts
    sed -i "s|extra_hosts: \[\]|extra_hosts:\n        - \"${MACHINE_FQDN}:${machine_ip}\"|" deployment_config.default.yaml
    # update
    sed -i "/extra_hosts:/{n;s/- .*/- \"${MACHINE_FQDN}:${machine_ip}\"/}" deployment_config.default.yaml
    make down up;
    popd
fi

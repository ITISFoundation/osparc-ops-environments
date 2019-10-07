#!/bin/bash
#
# Deploys in local host
#
#

set -euo pipefail
IFS=$'\n\t'

# Paths
this_script_dir=$(dirname "$0")
repo_basedir=$(realpath ${this_script_dir}/../)
scripts_dir=$(realpath ${repo_basedir}/scripts)

# VCS info on current repo
current_git_url=$(git config --get remote.origin.url)
current_git_branch=$(git branch | grep \* | cut -d ' ' -f2)


# Loads configurations variables
# See https://askubuntu.com/questions/743493/best-way-to-read-a-config-file-in-bash
source ${repo_basedir}/repo.config
source ${repo_basedir}/services/portainer/.env

cd $repo_basedir;

echo
echo "Deploying osparc on ${MACHINE_FQDN}..."

echo
echo "# starting portainer..."
pushd ${repo_basedir}/services/portainer; make up; popd

echo
echo starting traefik...
pushd ${repo_basedir}/services/traefik
# copy certificates to traefik
cp ${repo_basedir}/certificates/*.crt secrets/
cp ${repo_basedir}/certificates/*.key secrets/
# set MACHINE_FQDN
sed -i "s/MACHINE_FQDN=.*/MACHINE_FQDN=$MACHINE_FQDN/" .env
make up
popd

echo
echo starting minio...
pushd ${repo_basedir}/services/minio; make up; popd
while [ ! $(curl -s -o /dev/null -I -w "%{http_code}" ${MACHINE_FQDN}:30000/minio/health/ready) = 200 ]; do
    echo "waiting for minio to run..."
    sleep 5s
done
echo "waiting for the sake of waiting..."
sleep 10s

echo
echo starting portus/registry...
pushd ${repo_basedir}/services/portus
# copy certificates to portus
cp ${repo_basedir}/certificates/*.crt secrets/
cp ${repo_basedir}/certificates/*.key secrets/
# set MACHINE_FQDN
sed -i "s/MACHINE_FQDN=.*/MACHINE_FQDN=$MACHINE_FQDN/" .env
make up
popd

echo
echo starting monitoring...
# set MACHINE_FQDN
pushd ${repo_basedir}/services/monitoring
sed -i "s|GF_SERVER_ROOT_URL=.*|GF_SERVER_ROOT_URL=https://$MACHINE_FQDN/grafana|" grafana/config.monitoring
make up
popd

echo
echo starting graylog...
# set MACHINE_FQDN
pushd ${repo_basedir}/services/graylog;
sed -i "s|GRAYLOG_HTTP_EXTERNAL_URI=.*|GRAYLOG_HTTP_EXTERNAL_URI=https://$MACHINE_FQDN/graylog/|" .env
make up
popd

echo
echo "# starting deployment-agent for simcore..."
pushd ${repo_basedir}/services/deployment-agent; make up; popd

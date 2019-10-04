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
# TODO: rename *.config-> *.cfg
source ${repo_basedir}/repo.config 
source ${repo_basedir}/services/portainer/.env

cd $repo_basedir;

machine_ip=$(hostname -I | cut -d' ' -f1)


echo "Deploying osparc on ${MACHINE_FQDN}..."
echo "Do you to add this name to the local host file?"
select yn in "Yes" "No"; do
    case $yn in
    Yes ) \
        echo \
        ; \
        echo "adding ${MACHINE_FQDN} using ${machine_ip}"; \
        sudo make install-full-qualified-domain-name; \
        break;;
    No ) echo ""; \
        echo "using $(hostname -f)"
        break;;
    esac
done

echo
echo "Do you wish to use self-signed certificates?"
select yn in "Yes" "No"; do
    case $yn in
        Yes  ) \
            echo ""; \
            echo "creating certificates..."; \
            make create-certificates; \
            echo "installing certificates in host"; \
            make install-root-certificate; \
            break;;

        No ) echo ""; \
            mkdir -p certificates; \
            echo "Please copy your VALID certificates in $(pwd)/certificates and rename them to domain.crt/domain.key"; \
            echo "Please press any key when done"; \
            read -s -n 1 key; \
            echo \
            echo "Did you really put the certificate there"; \
            read -s -n 1 key; \
            break;;
    esac
done

echo
echo "# starting portainer..."
pushd ${repo_basedir}/services/portainer; make up; popd

echo
echo starting traefik...
pushd ${repo_basedir}/services/traefik
# copy certificates to traefik
cp ${repo_basedir}/certificates/* secrets/
# set MACHINE_FQDN
sed -i "s/MACHINE_FQDN=.*/MACHINE_FQDN=$MACHINE_FQDN/" .env
make up
popd

echo
echo starting minio...
pushd ${repo_basedir}/services/minio; make up; popd

echo
echo starting portus/registry...
pushd ${repo_basedir}/services/portus
# copy certificates to traefik
cp ${repo_basedir}/certificates/* secrets/
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
pushd ${repo_basedir}/services/deployment-agent; make build up; popd

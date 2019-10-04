#!/bin/bash
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

pushd $repo_basedir;
echo "Deploying osparc on local system..."
echo
echo "Do you wish to use self-signed certificates?"
select yn in "Yes" "No"; do
    case $yn in
        Yes | Y | y ) \
            echo ""; \
            echo "creating certificates..."; \
            make create-certificates; \
            echo "installing certificates in host"; \
            make install-root-certificate; \
            echo \
            echo "Please restart docker service and press any key when done"; \
            read -s -n 1 key; \
            echo \
            echo "Did you really restart docker service? (press any key when done)"; \
            read -s -n 1 key; \
            break;;

        No ) echo ""; \
            mkdir -p certificates; \
            echo "Please copy your VALID certificates in $pwd/certificates and rename them to domain.crt/domain.key"; \
            echo "Please press any key when done"; \
            read -s -n 1 key; \
            echo |
            echo "Did you really put the certificate there"; \
            read -s -n 1 key; \
            exit;;
    esac
done
# start portainer
echo
echo starting portainer
pushd ${repo_basedir}/services/portainer
make up
popd

# start traefik with self-signed certificates
echo
echo starting traefik
pushd ${repo_basedir}/services/traefik
cp ${repo_basedir}/certificates/rootca.crt secrets/rootca.crt
cp ${repo_basedir}/certificates/domain.crt secrets/domain.crt
cp ${repo_basedir}/certificates/domain.key secrets/domain.key
make up
popd

echo
echo starting minio
pushd ${repo_basedir}/services/minio
make up
popd

echo
echo starting portus/registry
pushd ${repo_basedir}/services/portus
cp ${repo_basedir}/certificates/rootca.crt secrets/rootca.crt
cp ${repo_basedir}/certificates/domain.crt secrets/portus.crt
cp ${repo_basedir}/certificates/domain.key secrets/portus.key
make up
popd

echo
echo starting monitoring
pushd ${repo_basedir}/services/monitoring
make up
popd

echo
echo starting graylog
pushd ${repo_basedir}/services/graylog
make up
popd

echo
echo starting deployment-agent/simcore
pushd ${repo_basedir}/services/deployment-agent
make build up
popd

popd

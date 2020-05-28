#!/bin/bash
#
# Context:
# - this script runs outside manager. Let us call this the `commanding machine`
# - there is a snapshot of https://github.com/ITISFoundation/osparc-ops.git ready
#
set -euo pipefail
IFS=$'\n\t'

# Paths
this_script_dir=$(dirname "$0")
repo_basedir=$(realpath $(this_script_dir)/../)
scripts_dir=$(realpath $(repo_basedir)/scripts)

# VCS info on current repo
current_git_url = $(git config --get remote.origin.url)
current_git_branch = $(git branch | grep \* | cut -d ' ' -f2)

# Loads configurations variables
# See https://askubuntu.com/questions/743493/best-way-to-read-a-config-file-in-bash
. $(repo_basedir)/scripts/deploy.config
. $(repo_basedir)/services/portainer/env.config

# Deploying portainer in the manager host
scp -r ${repo_basedir}/services/portainer ${ENVIRONMENT_MANAGER_NODE}:portainer
ssh ${ENVIRONMENT_MANAGER_NODE} "pushd portainer; make up"

# Labeling nodes
ssh ${ENVIRONMENT_MANAGER_NODE} "docker node update --label-add minio1=true ${ENVIRONMENT_MANAGER_NODE}"
ssh ${ENVIRONMENT_MANAGER_NODE} "docker node update --label-add minio2=true worker1"
ssh ${ENVIRONMENT_MANAGER_NODE} "docker node update --label-add minio3=true worker2"
ssh ${ENVIRONMENT_MANAGER_NODE} "docker node update --label-add minio4=true worker3"

ssh ${ENVIRONMENT_MANAGER_NODE} "docker node update --label-add postgres=true ${ENVIRONMENT_MANAGER_NODE}"


# Deploying stacks via the portainer
portainer_url = ${ENVIRONMENT_MANAGER_NODE}:9000
portainer_password = ${PORTAINER_ADMIN_PWD}
deploy = ${scripts_dir}/scripts/portainer-deploy-stack.sh

pushd osparc-ops/services/graylog
${deploy} --repo_url=${current_git_url} \
            --repo_user=${REPO_USER} --repo_password=${REPO_PASSWORD} \
            --repo_branch=${current_git_branch} \
            --portainer_url=${portainer_url} --portainer_user=admin \
            --portainer_password=${portainer_password} --stack_path=services/graylog/.stack.yml
popd

pushd osparc-ops/services/monitoring
${deploy} --repo_url=${current_git_url} \
            --repo_user=${REPO_USER} --repo_password=${REPO_PASSWORD} \
            --repo_branch=${current_git_branch} \
            --portainer_url=${portainer_url} --portainer_user=blah \
            --portainer_password=blah --stack_path=services/monitoring/.stack.yml
popd

pushd osparc-ops/services/minio
${deploy} --repo_url=${current_git_url} \
            --repo_user=${REPO_USER} --repo_password=${REPO_PASSWORD} \
            --repo_branch=${current_git_branch} \
            --portainer_url=${portainer_url} --portainer_user=blah \
            --portainer_password=blah --stack_path=services/minio/.stack.yml
popd

pushd osparc-ops/services/deployment-agent
${deploy} --repo_url=${current_git_url} \
            --repo_user=${REPO_USER} --repo_password=${REPO_PASSWORD} \
            --repo_branch=${current_git_branch} \
            --portainer_url=${portainer_url} --portainer_user=blah \
            --portainer_password=blah --stack_path=services/deployment-agent/.stack.yml
popd

# git clone https://git.speag.com/oSparc/osparc-ops-environments.git
# git checkout -b my/environment

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
scripts_dir=$(realpath $(this_script_dir))
repo_basedir=$(realpath $(this_script_dir)/../)

# VCS info on current repo
current_git_url = $(git config --get remote.origin.url)
current_git_branch = $(git branch | grep \* | cut -d ' ' -f2)

# Loads configurations variables
# See https://askubuntu.com/questions/743493/best-way-to-read-a-config-file-in-bash
. $(repo_basedir)/repo.config
. $(repo_basedir)/services/portainer/env.config

# Deploying portainer in the manager host
scp -r ${repo_basedir}/services/portainer manager1:portainer
ssh manager1 "pushd portainer; make up"

# Labeling nodes
ssh manager1 "docker node update --label-add minio1=true manager1"
ssh manager1 "docker node update --label-add minio2=true worker1"
ssh manager1 "docker node update --label-add minio3=true worker2"
ssh manager1 "docker node update --label-add minio4=true worker3"

ssh manager1 "docker node update --label-add postgres=true manager1"


# Deploying stacks via the portainer
portainer_url = manager1:9000
portainer_password = ${PORTAINER_ADMIN_PWD}
portainer = ${scripts_dir}/scripts/portainer.sh

cd osparc-ops/services/graylog
${portainer} --repo_url=${current_git_url} \
            --repo_user=${REPO_USER} --repo_password=${REPO_PASSWORD} \
            --repo_branch=${current_git_branch} --env=.env \
            --portainer_url=${portainer_url} --portainer_user=admin \
            --portainer_password=${portainer_password} --stack_path=services/graylog/.stack.yml
popd

pushd osparc-ops/services/monitoring
${portainer} --repo_url=${current_git_url} \
            --repo_user=${REPO_USER} --repo_password=${REPO_PASSWORD} \
            --repo_branch=${current_git_branch} --env=.env \
            --portainer_url=${portainer_url} --portainer_user=blah \
            --portainer_password=blah --stack_path=services/monitoring/.stack.yml
popd

pushd osparc-ops/services/minio
${portainer} --repo_url=${current_git_url} \
            --repo_user=${REPO_USER} --repo_password=${REPO_PASSWORD} \
            --repo_branch=${current_git_branch} --env=.env \
            --portainer_url=${portainer_url} --portainer_user=blah \
            --portainer_password=blah --stack_path=services/minio/.stack.yml
popd

pushd osparc-ops/services/deployment-agent
${portainer} --repo_url=${current_git_url} \
            --repo_user=${REPO_USER} --repo_password=${REPO_PASSWORD} \
            --repo_branch=${current_git_branch} --env=.env \
            --portainer_url=${portainer_url} --portainer_user=blah \
            --portainer_password=blah --stack_path=services/deployment-agent/.stack.yml
popd

# git clone https://git.speag.com/oSparc/osparc-ops-environments.git
# git checkout -b my/environment

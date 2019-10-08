#!/bin/bash
# as of http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

repo_url=$1
repo_user=$2
repo_password=$3
repo_branch=$4
env=$5
portainer_url=$
portainer_user
portainer_password
stack_path
swarm_endpoint=1 # as long as we have one swarm per container


echo
echo authentifying with ${portainer_url}...
bearer_code=$(curl --silent --request POST ${portainer_url}/api/auth -data "{\"Username\":\"${portainer_user}\", \"Password\":\"${portainer_password}\"}" | jq -r .jwt)
echo authentication with ${portainer_url} completed


echo
echo getting swarm ID from endpoint ${swarm_endpoint}
swarm_id=$(curl --header "Authorization: Bearer ${bearer_code}" --request GET ${portainer_url}/api/endpoints/${swarm_endpoint}/docker/swarm | jq -r .ID)
echo found swarm ID is ${swarm_id}

stack_name= #TODO: deduce from stack_path

echo
echo creating new stack...
curl --header "Authorization: Bearer ${bearer_code}"\
    --header "Content-Type: application/json"\
    --data "{\"Name\":\"${stack_name}\", \"SwarmID\":\"${swarm_id}\",
        \"RepositoryURL\":\"${repo_url}\", \"RepositoryReferenceName\":\"${repo_branch}\", \"ComposeFilePathInRepository\": \"${stack_path}\",
        \"RepositoryAuthentication\":true, \"RepositoryUsername\": \"${repo_user}\", \"RepositoryPassword\": \"${repo_password}\"}"\
    --request POST "${portainer_url}/api/stacks?type=1&method=repository&endpointId=${swarm_endpoint}"
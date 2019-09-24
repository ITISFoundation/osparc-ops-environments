#!/bin/bash
# as of http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

function usage()
{
    echo "if this was a real script you would see something useful here"
    echo ""
    echo "./simple_args_parsing.sh"
    echo "\t-h --help"
    echo "\t--environment=$ENVIRONMENT"
    echo "\t--db-path=$DB_PATH"
    echo ""
}

not_set="not set"

repo_url=$not_set
repo_user=$not_set
repo_password=$not_set
repo_branch=$not_set
# env=$5
portainer_url=$not_set
portainer_user=$not_set
portainer_password=$not_set
stack_name=$not_set
stack_path=$not_set

while [[ $# -gt 0 ]]; do
    PARAM="${1}"
    case ${PARAM} in
        -h | --help)
            usage
            exit
            ;;
        --repo_url)
            repo_url="${2}"
            ;;
        --repo_user)
            repo_user="${2}"
            ;;
        --repo_password)
            repo_password="${2}"
            ;;
        --repo_branch)
            repo_branch="${2}"
            ;;
        --portainer_url)
            portainer_url="${2}"
            ;;
        --portainer_user)
            portainer_user="${2}"
            ;;
        --portainer_password)
            portainer_password="${2}"
            ;;
        --stack_name)
            stack_name="${2}"
            ;;
        --stack_path)
            stack_path="${2}"
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift 2
done

swarm_endpoint=1 # as long as we have one swarm per container


echo
echo authentifying with ${portainer_url}...
bearer_code=$(curl --silent --request POST ${portainer_url}/api/auth --data "{\"Username\":\"${portainer_user}\", \"Password\":\"${portainer_password}\"}" | jq -r .jwt)
echo authentication with ${portainer_url} completed


echo
echo getting swarm ID from endpoint ${swarm_endpoint}
swarm_id=$(curl --header "Authorization: Bearer ${bearer_code}" --request GET ${portainer_url}/api/endpoints/${swarm_endpoint}/docker/swarm | jq -r .ID)
echo found swarm ID is ${swarm_id}

# stack_name= #TODO: deduce from stack_path

echo
echo creating new stack ${stack_name}...
curl --header "Authorization: Bearer ${bearer_code}"\
    --header "Content-Type: application/json"\
    --data "{\"Name\":\"${stack_name}\", \"SwarmID\":\"${swarm_id}\",
        \"RepositoryURL\":\"${repo_url}\", \"RepositoryReferenceName\":\"${repo_branch}\", \"ComposeFilePathInRepository\": \"${stack_path}\",
        \"RepositoryAuthentication\":true, \"RepositoryUsername\": \"${repo_user}\", \"RepositoryPassword\": \"${repo_password}\"}"\
    --request POST "${portainer_url}/api/stacks?type=1&method=repository&endpointId=${swarm_endpoint}"

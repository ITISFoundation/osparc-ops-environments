#!/bin/bash


# SEE http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# Default INPUTS ---------------
repo_url=$(git config --get remote.origin.url)
repo_branch=sanderegg-deplyment_script_master

repo_user=undefined
repo_password=undefined

stack_path=services/monitoring

# ????
env=undefined

portainer_url=http://127.0.0.1:9000
portainer_user=admin
portainer_password=adminadmin

usage="$(basename "$0") [-h] [--key=value]

Request portainer to start a stack whose configuration is in a git repo

where keys are:
    -h  show this help text
    --repo_url             (default: ${repo_url})
    --repo_branch          (default: ${repo_branch})
    --stack_path           (default: ${stack_path})
    --repo_user            (default: ${repo_user})
    --repo_password        (default: ${repo_password})
    --portainer_url        (default: ${portainer_url})
    --portainer_user       (default: ${portainer_user})
    --portainer_password   (default: ${portainer_password})
    --repo_url             (default: ${repo_url})"

# parse command line
# SEE https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
# TODO: reduce this
for i in "$@"
do
case $i in
    --repo_url=*)
    repo_url="${i#*=}"
    shift # past argument=value
    ;;
    --repo_user=*)
    repo_user="${i#*=}"
    shift # past argument=value
    ;;
    --repo_password=*)
    repo_password="${i#*=}"
    shift # past argument=value
    ;;
    --repo_branch=*)
    repo_branch="${i#*=}"
    shift # past argument=value
    ;;
    ##
    --env=*)
    env="${i#*=}"
    shift # past argument=value
    ;;
    ##
    --portainer_url=*)
    portainer_url="${i#*=}"
    shift # past argument=value
    ;;
    --portainer_user=*)
    portainer_user="${i#*=}"
    shift # past argument=value
    ;;
    --portainer_password=*)
    portainer_password="${i#*=}"
    shift # past argument=value
    ;;
    --stack_path=*)
    stack_path="${i#*=}"
    shift # past argument=value
    ;;
    ##
    :|*|--help|-h)
    echo "$usage" >&2
    exit 1
    ;;
esac
done


stack_name="${stack_path##*/}"

# as long as we have one swarm per container??
swarm_endpoint=1 

#-------------------------------------------------------------------------


## authentifying with ${portainer_url}...
echo
echo "Authentifying with ${portainer_url}..."
bearer_code=$(curl --silent \
    -d "{\"Username\":\"${portainer_user}\", \"Password\":\"${portainer_password}\"}" \
    -H "Content-Type: application/json"\
    -X POST ${portainer_url}/api/auth \
    | jq -r .jwt)
echo "Authentication with ${portainer_url} completed"



## "getting swarm ID from endpoint ${swarm_endpoint}..."
echo
echo "Getting swarm ID from endpoint ${swarm_endpoint}..."
swarm_id=$(curl --silent \
    --header "Authorization: Bearer ${bearer_code}"\
    --request GET ${portainer_url}/api/endpoints/${swarm_endpoint}/docker/swarm\
    | jq -r .ID)
echo "Round swarm ID is ${swarm_id}"

## "creating new stack...""
echo
echo "Creating new stack ${stack_name}..."
curl \
    --header "Authorization: Bearer ${bearer_code}" \
    --header "Content-Type: application/json" \
    --data "{ \"Name\":\"${stack_name}\",  \"SwarmID\":\"${swarm_id}\", \
        \"RepositoryURL\":\"${repo_url}\", \"RepositoryReferenceName\":\"${repo_branch}\", \"ComposeFilePathInRepository\": \"${stack_path}\",
        \"RepositoryAuthentication\":true, \"RepositoryUsername\": \"${repo_user}\", \"RepositoryPassword\": \"${repo_password}\"}"\
    --request POST "${portainer_url}/api/stacks?type=1&method=repository&endpointId=${swarm_endpoint}"
echo "DONE"
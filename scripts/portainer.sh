#!/bin/bash

# SEE http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# Default INPUTS ---------------
repo_url="https://github.com/pcrespov/osparc-ops" ## TODO: convert $(git config --get remote.origin.url) into https
repo_branch="refs/heads/$(git rev-parse --abbrev-ref HEAD)"
repo_user=undefined
repo_password=undefined


stack_path=services/monitoring/docker-compose.yml

# TODO: Environment variables?
#   "Env": [
#     {
#       "name": "MYSQL_ROOT_PASSWORD",
#       "value": "password"
#     }
#   ]
env=undefined

portainer_url=http://127.0.0.1:9000
portainer_user=admin
portainer_password=adminadmin

usage="$(basename "$0") [-h] [--key=value]

Request portainer to start a stack whose configuration is in a git repo

where keys are:
    -h, --help  show this help text
    --repo_url             (default: ${repo_url})
    --repo_branch          (default: ${repo_branch})
    --stack_path           (default: ${stack_path})
    --portainer_url        (default: ${portainer_url})
    --portainer_user       (default: ${portainer_user})
    --portainer_password   (default: ${portainer_password})

    only for private repos
    --repo_user:            (default: ${repo_user})
    --repo_password:        (default: ${repo_password})"

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
    --repo_branch=*)
    repo_branch="${i#*=}"
    shift 
    ;;
    --repo_user=*)
    repo_user="${i#*=}"
    shift 
    ;;
    --repo_password=*)
    repo_password="${i#*=}"
    shift 
    ;;
    --stack_path=*)
    stack_path="${i#*=}"
    shift 
    ;;
    ##
    --env=*)
    env="${i#*=}"
    shift 
    ;;
    ##
    --portainer_url=*)
    portainer_url="${i#*=}"
    shift 
    ;;
    --portainer_user=*)
    portainer_user="${i#*=}"
    shift 
    ;;
    --portainer_password=*)
    portainer_password="${i#*=}"
    shift 
    ;;
    ##
    :|*|--help|-h)
    echo "$usage" >&2
    exit 1
    ;;
esac
done


# TODO: convert env='key=value;key2=value2' into
#   "Env": [
#     {
#       "name": "MYSQL_ROOT_PASSWORD",
#       "value": "password"
#     }
#   ]


stack_name=$(basename $(dirname ${stack_path}))

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
echo " - Repo         : ${repo_url}"
echo " - Branch       : ${repo_branch}"
echo " - compose file : ${stack_path}"

## SEE https://app.swaggerhub.com/apis/deviantony/Portainer/1.22.0/#/stacks/StackCreate
# Example of body:
#
# {
#   "Name": "myStack",
#   "SwarmID": "jpofkc0i9uo9wtx1zesuk649w",
#   "StackFileContent": "version: 3\n services:\n web:\n image:nginx",
#   "RepositoryURL": "https://github.com/openfaas/faas",
#   "RepositoryReferenceName": "refs/heads/master",
#   "ComposeFilePathInRepository": "docker-compose.yml",
#   "RepositoryAuthentication": true,
#   "RepositoryUsername": "myGitUsername",
#   "RepositoryPassword": "myGitPassword",
#   "Env": [
#     {
#       "name": "MYSQL_ROOT_PASSWORD",
#       "value": "password"
#     }
#   ]
# }
#

# TODO: shorten
JSON_STRING=$(cat <<-EOM
{
   "Name": "${stack_name}",
   "SwarmID": "${swarm_id}",
   "RepositoryURL": "${repo_url}",
   "RepositoryReferenceName": "${repo_branch}",
   "ComposeFilePathInRepository": "${stack_path}",
   "RepositoryAuthentication": true,
   "RepositoryUsername":"${repo_user}",
   "RepositoryPassword":"${repo_password}"
}
EOM
)

if [ "$repo_user" == undefined ]; then
JSON_STRING=$(cat <<-EOM
{
   "Name": "${stack_name}",
   "SwarmID": "${swarm_id}",
   "RepositoryURL": "${repo_url}",
   "RepositoryReferenceName": "${repo_branch}",
   "ComposeFilePathInRepository": "${stack_path}",
   "RepositoryAuthentication": false
}
EOM
)
fi


curl --request POST "${portainer_url}/api/stacks?type=1&method=repository&endpointId=${swarm_endpoint}" \
    --header "Authorization: Bearer ${bearer_code}" \
    --header "Content-Type: application/json" \
    --data "$JSON_STRING"


# TODO: query output with jq
echo "DONE"

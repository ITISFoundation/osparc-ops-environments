#!/bin/bash
#
# Extract the database from the current host and copy it in a new host
#
#
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'
# shellcheck disable=1090,1091
source .env


usage()
{
    echo "usage: db-restore.sh [-n --network]"
    echo "-n --network : Add the network monitored_network to be able to connect to the pgsql service (When the pgsql server is in a swarm)"
}

network="--network=""bridge"""

for var in "$@"
do
    if [ "$var" = "-n" ] || [ "$var" = "--network" ]; then
        network="--network=""monitored_network"""
    else
        usage
        exit
    fi
done

read -p -r "Are you sure ? You are going to delete the database simcoredb in the host ${POSTGRES_HOST} (y/n)? " yn
if [ "$yn" = "y" ]; then
    echo "Droping and recreating the database in the destination host"
    docker run -it --rm \
    "$network" \
    -v "$(pwd)":/var/pgdata \
    jbergknoff/postgresql-client postgresql://"${POSTGRES_USER}":"${POSTGRES_PASSWORD}"@"${POSTGRES_HOST}":"${POSTGRES_PORT}"/postgres \
    -c "DROP DATABASE ${POSTGRES_DB};" -c "CREATE DATABASE ${POSTGRES_DB};" \
    -c "CREATE ROLE ${POSTGRES_GRAFANA_USER} with LOGIN ENCRYPTED PASSWORD '${POSTGRES_GRAFANA_PASSWORD}';" \
    -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO ${POSTGRES_GRAFANA_USER};" \
    -c "\connect ${POSTGRES_DB}" -f "/var/pgdata/backup.sql"
fi

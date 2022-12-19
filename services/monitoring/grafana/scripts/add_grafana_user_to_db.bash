#!/bin/bash
#
# Add grafana user to host
#
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'
# shellcheck disable=1090,1091
source ../../.env


usage()
{
    echo "usage: add_grafana_user_to_db.bash [-n --network]"
    echo "-n --network : Add the network monitored_network to be able to connect to the pgsql service (When the pgsql server is in a swarm)"
}

network="--network=""monitored_network"""

for var in "$@"
do
    if [ "$var" = "-n" ] || [ "$var" = "--network" ]; then
        network="--network=""monitored_network"""
    else
        usage
        exit
    fi
done

### Chained commands with &&: Check if pg user exists via https://stackoverflow.com/questions/8546759/how-to-check-if-a-postgres-user-exists
### If not, create the user
docker run -it --rm \
"$network" \
-v /tmp:/var/pgdata \
jbergknoff/postgresql-client postgresql://"${POSTGRES_USER}":"${POSTGRES_PASSWORD}"@"${POSTGRES_PUBLIC_HOST}":"${POSTGRES_PORT}"/postgres \
-c "SELECT 1 FROM pg_roles WHERE rolname='${POSTGRES_GRAFANA_USER}'" | grep -q 1 && docker run -it --rm \
"$network" \
-v /tmp:/var/pgdata \
jbergknoff/postgresql-client postgresql://"${POSTGRES_USER}":"${POSTGRES_PASSWORD}"@"${POSTGRES_PUBLIC_HOST}":"${POSTGRES_PORT}"/postgres \
-c "DROP ROLE ${POSTGRES_GRAFANA_USER};" || echo "SKIPPING: role ${POSTGRES_GRAFANA_USER} already present. Please ignore any previous errors."
docker run -it --rm \
"$network" \
-v /tmp:/var/pgdata \
jbergknoff/postgresql-client postgresql://"${POSTGRES_USER}":"${POSTGRES_PASSWORD}"@"${POSTGRES_PUBLIC_HOST}":"${POSTGRES_PORT}"/postgres \
-c "CREATE ROLE ${POSTGRES_GRAFANA_USER} with LOGIN ENCRYPTED PASSWORD '${POSTGRES_GRAFANA_PASSWORD}';" \
-c "\connect ${POSTGRES_DB};" \
-c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO ${POSTGRES_GRAFANA_USER};" && \
echo Added user "${POSTGRES_GRAFANA_USER}" successfully

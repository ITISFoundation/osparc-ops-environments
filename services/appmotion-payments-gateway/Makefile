
# something to resolve
#  repo.config + template.env  -> .env
#

# resolve .env
source repo.config
envsubst < template.env > .env


# create
source .env
envsubst < docker_config.template > secret_docker_config
docker config create appmotion_payments_gateway_env ./secret_docker_config
rm secret_docker_config


# resolve config

# SEE https://skofgar.ch/dev/2020/08/how-to-quickly-replace-environment-variables-in-a-file/


# Regarding mariadb

PLEASE REMEMBER TO SET A PASSWORD FOR THE MariaDB root USER !
appmotion-payments-gateway-db-1   | To do so, start the server, then issue the following command:
appmotion-payments-gateway-db-1   | 
appmotion-payments-gateway-db-1   | '/usr/bin/mariadb-secure-installation'
appmotion-payments-gateway-db-1   | 
appmotion-payments-gateway-db-1   | which will also give you the option of removing the test
appmotion-payments-gateway-db-1   | databases and anonymous user created by default.  This is
appmotion-payments-gateway-db-1   | strongly recommended for production servers.
appmotion-payments-gateway-db-1   | 
appmotion-payments-gateway-db-1   | See the MariaDB Knowledgebase at https://mariadb.com/kb
appmotion-payments-gateway-db-1   | 
appmotion-payments-gateway-db-1   | Please report any problems at https://mariadb.org/jira
appmotion-payments-gateway-db-1   | 
appmotion-payments-gateway-db-1   | The latest information about MariaDB is available at https://mariadb.org/.
appmotion-payments-gateway-db-1   | 
appmotion-payments-gateway-db-1   | Consider joining MariaDB's strong and vibrant community:
appmotion-payments-gateway-db-1   | https://mariadb.org/get-involved/
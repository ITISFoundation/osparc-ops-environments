
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
# oSparc Simcore - Full Ops Stack with Monitoring and Debugging tools

## tl;dr
- In this repo's source path, create the file `.config.location` that contains the absolute full path to a oSparc Configuration Repo.
- `make help`
- For example: `make up-aws`



## Make sure to install `pre-commit`!
```
pip install pre-commit
pre-commit install
```

## Concepts:

The configuration (i.e. "env-vars") are seperated from the definitions of the ops-stack. In order for the ops-stack to start, configuration variables must be known. To do this, create the file `.config.location` in this repo's source path that contains the absolute full path to a oSparc Configuration Repo.


## Local deployment

### This code has been tested to run on a current Ubuntu machine with docker installed from the official docker repositories
### Docker on windows is not supported, as the handling of named docker volumes is different there from linux and bind-mounting named volumes fails.

### Prerequisits
Depending on your system configuration, you might have to ensure that
```
sudo chmod 666 /var/run/docker.sock
```

You need to have `jinja2` installed and working.

If you have multiple IP adressess set, the automatic creation of a docker-swarm might fail on your machine.
In this case, manually create a docker-swarm and specify the advertise IP-address you desire:

```
docker swarm init --advertise-addr 192.6.XXX.XXX
```

If you encounter self-signed SSL certificate related errors, ensure (in this order):
- The certificate authority (`rootca.crt`) has been imported into the target browser. Browsers are strict.
- Run `make down`. Run `docker system prune -a`. Ensure all services are stopped (check `docker service ls`). Manually purge all docker secrets (check `docker secret rm`). Run `cd certificates && make remove-root-certificate && make clean `
- Restart the docker daemon

### Run:

```
make up-local
cd scripts/provisionDatabase && make up
```

Then, create a test user with mail-address "test@example.org"


While this is not officially supported, you might be able to run this on WSL2, but only if you don't use Docker Desktop but the linux-only docker client on wsl2.

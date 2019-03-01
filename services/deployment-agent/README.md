# Auto-deployment agent

This docker service brings continuous deployment (**CD**) of a docker stack inside a running docker swarm. It is a configurable tool that can monitor any number of git repositories for changes - complete repo or specific files -, generate using a configurable command line call a docker stack file and finally monitor any number of docker repositories referenced by the generated stack file. When changes are detected any number of portainer instances will be updated to (re-)deploy the stack file.
Optionally the tool can also send a configurable notification to an external service (currently only Mattermost is supported).

## Configuration

A sample configuration file for the auto deployment agent is visible in [here](src/simcore_service_deployment_agent/tests/test-config.yaml).



## Deployment

The auto deployment agent may be deployed locally provided a configuration file named deployment_config.yaml is provided at the same level as the Makefile. If none is provided the test-configuration will be automatically copied (which automatically deploys the simcore core platform with some default values).

```bash
make build
make up
```

This will initialise a docker swarm, and a stack containing a Portainer instance, a Portainer agent and the auto-deployment agent. The auto-deployment will start by fetching the defined repositories, generate the stack file and deploy the stack file into the swarm.

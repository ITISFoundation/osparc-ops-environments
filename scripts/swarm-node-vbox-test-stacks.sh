#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

echo "======> State of current cluster"
docker-machine ssh manager1 "docker node ls"
docker-machine ls

# copy code inside
echo "======> Updating the stack configs $(pwd)/../services ..."
docker-machine scp -r $(pwd)/../services manager1:service

# portaier stack
echo "======> Deploying portainer stack ..."
docker-machine ssh manager1 "cd service/portainer; make up"
docker-machine ssh manager1 "docker stack ls"

# monitoring stack 
echo "======> Deploying monitoring stack ..."
docker-machine ssh manager1 "cd service/monitoring; make up"
docker-machine ssh manager1 "docker stack ls"

# responsive ?
echo "======> Testing services..."
curl  $(docker-machine ip manager1):9000 | grep portainer
curl  $(docker-machine ip manager1):9090/graph | grep Prometheus
curl  $(docker-machine ip manager1):3000/login | grep grafana


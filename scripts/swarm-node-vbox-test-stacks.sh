#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

echo "======> State of current cluster"
docker-machine ssh manager1 "docker node ls"
docker-machine ls

# install python3
docker-machine ssh manager1 "tce-load -iw python3.6"
docker-machine ssh manager1 "python3 -m venv .venv"
docker-machine ssh manager1 ".venv/bin/pip3 install --upgrade pip wheel setuptools"
# install docker-compose
docker-machine ssh manager1 ".venv/bin/pip3 install docker-compose"

# copy code inside
echo "======> Updating the stack configs $(pwd)/../services ..."
docker-machine scp -r $(pwd)/services manager1:service

# portainer stack
echo "======> Deploying portainer stack ..."
docker-machine ssh manager1 "source .venv/bin/activate; \
                            cd service/portainer; \
                            make up"
docker-machine ssh manager1 "docker stack ls"

# logging stack
echo "======> Deploying graylog stack ..."
manager_ip = docker-machine ip manager1
docker-machine ssh manager1 "source .venv/bin/activate; \
                            cd service/graylog; \
                            sed -i 's/127.0.0.1/${manager_ip}/g' .env.config
                            make up"
docker-machine ssh manager1 "docker stack ls"

# minio stack
echo "======> Deploying minio stack ..."
# label the machines
docker-machine ssh manager1 "docker node update --label-add minio1=true manager1"
docker-machine ssh manager1 "docker node update --label-add minio2=true worker1"
docker-machine ssh manager1 "docker node update --label-add minio3=true worker2"
docker-machine ssh manager1 "docker node update --label-add minio4=true worker3"
# configure .env to create 4 minios
docker-machine ssh manager1 "source .venv/bin/activate; \
                            cd service/minio; \
                            sed -i 's/MINIO_NUM_MINIOS=1/MINIO_NUM_MINIOS=4/g' .env.config \
                            make up"
docker-machine ssh manager1 "docker stack ls"

# monitoring stack
echo "======> Deploying monitoring stack ..."
docker-machine ssh manager1 "cd service/monitoring; \
                            make up"
docker-machine ssh manager1 "docker stack ls"

# deployer stack
echo "======> Deploying auto-deployer stack ..."
docker-machine ssh manager1 "cd service/deployment-agent; \
                            make up"
docker-machine ssh manager1 "docker stack ls"

# responsive ?
echo "======> Testing services..."
curl  $(docker-machine ip manager1):9000 | grep portainer
curl  $(docker-machine ip manager1):9090/graph | grep Prometheus
curl  $(docker-machine ip manager1):3000/login | grep grafana


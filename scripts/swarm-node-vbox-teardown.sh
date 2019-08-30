#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Taken from https://github.com/docker/labs

### Warning: This will remove all docker machines running ###

# Stop machines
docker-machine stop $(docker-machine ls -q)

# remove machines
docker-machine rm -y $(docker-machine ls -q)

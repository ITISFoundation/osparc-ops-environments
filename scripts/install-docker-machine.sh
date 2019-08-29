#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# docker-machine
VERSION ?= 0.16.1
curl -L https://github.com/docker/machine/releases/download/v${VERSION}/docker-machine-`uname -s`-`uname -m` >/tmp/docker-machine &&
    chmod +x /tmp/docker-machine &&
    sudo cp /tmp/docker-machine /usr/local/bin/docker-machine

#  latest virtual box
sudo add-apt-repository multiverse && sudo apt-get update
sudo apt install -y virtualbox
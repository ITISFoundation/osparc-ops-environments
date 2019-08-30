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


# NOTE: 
#
# When installed virtualbox, ``docker swarm init`` in th host will error
#
#   Error response from daemon: could not choose an IP address to advertise since this system has multiple addresses on different interfaces (192.***.***.*** on eno1 and 192.***.***** on vboxnet0) - specify one with --advertise-addr
#
# Can remove vboxnet0 as
#   VBoxManage hostonlyif remove vboxnet0
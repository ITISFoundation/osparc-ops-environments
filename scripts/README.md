# testing workflow

Scripts for a manual exploratory workflow

tools

    $ ./install-docker-machine.sh

create clustes of virtual machines

    $ ./swarm-node-vbox-setup.sh

deploy and test

    $ ./swarm-node-vbox-test-stacks.sh

tear down cluster

    $ ./swarm-node-vbox-teardown.sh

# Platform compatibility in scripting

When writing new scripts, please be aware of possible compatibility issues between different platforms and include your util functions in ``portable.sh``

Import this file in your scripts placed in the same folder using
```
source "$( dirname "${BASH_SOURCE[0]}" )/portable.sh"
```
Or use a relative path from the current working directory of the executing script.

#### sed
Use ``$psed`` instead of ``sed`` to make substitutions in your files.

TODO: add checks and integrate in travis!
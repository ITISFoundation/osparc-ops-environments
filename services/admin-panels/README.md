# adminpanels stack

## quickstart / tl; dr
1. In the admin jupyter, open a terminal
2. Run `sudo adminPanelsGitInit.bash` to update the admin panels from github to the latest version
3. Navigate to `~/osparc-support`
4. Run admin panels


## Details

This admin-panel service is attached to all relevant docker networks of the sicore stack to communicate with postgres, redis, and simcore microservices.
All relevant credentials are previded as env-vars in the admin-panels.
The admin-panels should be coded in a way to use the env-vars provided by the admin-panel service

If you make modifications to the admin-panels, they cannot be pushed to git directly. You are expected to make a formal PR to the `osparc-support` repo on github.

## Caveats

- Currently, the admin panels are not designed to handle multiple parallel users. Weird things may happen/
- There is no data persistancy in the admin panel jupyter. It is recommended to always execute a fresh pull from github (via `sudo adminPanelsGitInit.bash`) before using the panels
- The admin-panels will not work for dalco-staging, as two deployments on the same swarm can currently not be handled.

# admin-panels stack


## Details

This admin-panel service is attached to all relevant docker networks of the simcore stack to communicate with postgres, redis, and simcore microservices.
All relevant credentials are provided as env-vars in the admin-panels.

If you make modifications to the admin-panels inside the admin-panels jupyter (i.e. on a live deployment), they cannot be pushed to git directly. You are expected to make a formal PR to this repo on github.

## Caveats

- Currently, the admin panels are not designed to handle multiple parallel users. Weird things may happen.
- There is no data persistancy in the admin panel jupyter. Files have to be added to the git-repo https://github.com/ITISFoundation/osparc-ops-environments via PR to be persistant
- The admin-panels will not work for dalco-staging, as two deployments on the same swarm can currently not be handled.

## How to add new admin scripts
- Make a PR to https://github.com/ITISFoundation/osparc-ops-environments and simply drop the `.py` or `.ipynb` files in  `osparc-ops-environments/services/admin-panels/data`

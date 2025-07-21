## Updating chart dependencies

1. Execute `make helmfile-deps`
2. Copy generated content to respective `Chart.lock`

Avoid error: `Error: the lock file (Chart.lock) is out of sync with the dependencies file (Chart.yaml). Please update the dependencies`

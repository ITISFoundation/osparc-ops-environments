# oSparc Simcore - Full Ops Stack with Monitoring and Debugging tools

<!-- BADGES: LINKS TO IMAGES. Default to https://shields.io/ ------------------------------>
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)]([https://developer.mend.io/](https://developer.mend.io/github/ITISFoundation/osparc-ops-environments))
<!------------------------------------------------------------------------------------------>

## tl;dr
- In this repo's source path, create the file `.config.location` that contains the absolute full path to a oSparc Configuration Repo.
- `make help`
- For example: `make up-aws`

## Make sure to install `pre-commit`!
```
pip install pre-commit
pre-commit install
```

## Concepts:

The configuration (i.e. "env-vars") are seperated from the definitions of the ops-stack. In order for the ops-stack to start, configuration variables must be known. To do this, create the file `.config.location` in this repo's source path that contains the absolute full path to a oSparc Configuration Repo.

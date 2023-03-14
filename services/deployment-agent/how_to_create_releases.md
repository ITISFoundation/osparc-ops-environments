### How to release
- 1. Make an osparc-simcore release
- 2. Make an osparc-ops-environments release
- 3. Make an osparc-ops-deployment-configuration release

### How to release osparc-simcore
Please consider `osparc-simcore/docs/releasing-workflow-instructions.md`

### How to release osparc-ops-environments
- Clone the repository
- Check out the desired commit (if in doubt, the HEAD of branch `main`)
- Run `make help` to get help on the commands `make release-prod` and `make release-staging`

### How to release osparc-ops-deployment-configuration
- Clone the repository
- Check out the desired commit (if in doubt, the HEAD of branch corresponding to each deployment)
- Run `make help` to get help on the commands `make release-prod` and `make release-staging`

### Notes on tag-syncing:
- For staging and production, the deployment agent will only push new code if the tags of all watched repos match, i.e. if `make release` has been run everywhere
- Tags are case-sensitive (`"testtag" != "TestTag"`)
- For the osparc-ops-deployment-configuration repo, a special tag prefixing the release-name with `${BRANCH_NAME}/` is created. This is taken into account by the deployment agent by wrapping the part after the `/` of the tag into a regex-capture-group and thereby strip the first part of the tag name away.

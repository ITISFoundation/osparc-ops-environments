# Object

This script pull sim4life images (s4l-core-lite, sym-server-dy) to all GPUs node on the selected deploy. Available deploys are :
- aws-staging
- aws-production
- master
- dalco-staging
- dalco-production
- tip


# Usage

- Create a .env from template.env and fill it (Aws credentials are in osparc-infra)

- Run
```
`./launch ${deploy}`
```

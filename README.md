# oSparc Simcore Operations Development

[![Build Status](https://travis-ci.com/ITISFoundation/osparc-ops.svg?branch=master)](https://travis-ci.com/ITISFoundation/osparc-ops)

Tools for oSPARC deployment and management (not directly part of osparc platform)

## Contents

### services

Support services used for the deployment of the oSPARC platform:

- [Portainer](services/portainer/): Docker management tool
- [Traefik](services/traefik/): Reverse-proxy to handle secured entrypoints
- [Minio](services/minio/): AWS compatible S3 storage
- [Portus](services/portus/): Docker images registry
- [Graylog](services/graylog): Logs aggregator
- [Jaeger](services/jaeger): Tracing system
- [Monitoring](services/monitoring/): Prometheus/Grafana monitoring
- [Adminer](services/adminer): Database management
- [Maintenance](services/maintenance/): Notebooks for internal maintenance (in development)
- [Deployment agent](services/deployment-agent/): SIM-Core auto deploy tool

- [Simcore](services/simcore): Configuration for [osparc-simcore](https://github.com/ITISFoundation/osparc-simcore)

### usage

```console
git clone https://github.com/ITISFoundation/osparc-ops.git
cd osparc-ops
make help
```

### WSL deployment

#### WSL1

If you are using WSL1, clone the repository in a path accessible by the Windows filesystem (typically in /mnt/c/my_path and not in /home). You need to ensure [Ensure Volume Mounts Work](https://nickjanetakis.com/blog/setting-up-docker-for-windows-and-wsl-to-work-flawlessly) (Section Volume Mounts Work)

#### WSL2

Clone the repository directly into the WSL2 filesystem (in /home for example).


#### local deployment
  ```console
  make up-local
  ```
A self-signed certificate may be generated. The system host file may be modified using the default **osparc.local** fully qualified domain name (FQDN) to point to the local machine.

The services above will be deployed and pre-configured on the following endpoints:
  - Traefik: [https://monitoring.osparc.local/dashboard/#/](https://monitoring.osparc.local/dashboard/#/)
  - Portainer: [https://monitoring.osparc.local/portainer/](https://monitoring.osparc.local/portainer/)
  - Minio: [https://storage.osparc.local/minio/](https://storage.osparc.local/minio/)
  - Deployment agent: no UI
  - Graylog: [https://monitoring.osparc.local/graylog/](https://monitoring.osparc.local/graylog/)
  - Jaeger: [https://monitoring.osparc.local/jaeger/](https://monitoring.osparc.local/jaeger/)
  - Adminer: [https://monitoring.osparc.local/adminer](https://monitoring.osparc.local/adminer?server=simcore_postgres%3A5432&username=scu&db=simcoredb)
  - Monitoring: [https://monitoring.osparc.local/grafana/](https://monitoring.osparc.local/grafana/) and Prometheus: [https://monitoring.osparc.local/prometheus/](https://monitoring.osparc.local/prometheus/)
  - Maintenance: not reversed proxied yet
  - **Simcore:** **[https://osparc.local](https://osparc.local)**

Default credentials are the following:
  user: admin
  password: adminadmin


To change the default domain name and/or services credentials edit [repo.config](repo.config) file.

#### cluster deployment

Each service may be configured and deployed according to the needs. Please see each service README.md file to gather information.

### virtual_cluster (deprecated)

- Deploy a virtual cluster to your own host.  Suitable as an infrastructure plaform for oSPARC Simcore.

### FAQ

The auto-generated ssl certificates are detected as invalid in my brower ?

You need to do a full cleaning of your installation.
```console
make reset-prune
```
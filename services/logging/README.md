# Graylog logging stack for [osparc-simcore]

Creates a stack to aggregate logs from any running stack/containers. The logs are pulled from the running container by [Logspout-GELF](https://github.com/Vincit/logspout-gelf), converted and sent to the [Graylog server](https://www.graylog.org/), which uses [MongoDB](https://www.mongodb.com/) and [elasticsearch](https://www.elastic.co/) as backends.

## Usage

```console
make help
make up
make down
```

## Graylog workflow overview
![Graylog workflow overview](./GraylogWorkflow.png)

## Configuration for graylog - The Principles

1. Create a GELF UDP INPUT
2. Show incoming messages
3. All the docker container messages shall be visible
4. Use *content packs* to preconfigure dashboards, alerts, pipelines, ...
5. Send a message following through the console:

```console
echo -n '{ "version": "1.1", "host": "example.org", "short_message": "A short message", "level": 5, "_some_info": "foo" }' | nc -w0 -u localhost 12201
```

### In oSparc: Use Dual Logging

Dual Logging is available, see: https://docs.docker.com/config/containers/logging/dual-logging/

The file `/etc/docker/daemon.json` is configured to include the following options. (HINT: Restart the docker daemon after any modifications of the file)

```json
    "log-driver": "gelf",
    "log-opts": {
      "gelf-address": "udp://127.0.0.1:12201"
    }
```

UDP Post 12201 is used by graylog and exposed as an ingress port.


## Accessing Web-browser API

The link provided in the documentation is wrong. [The working one](https://community.graylog.org/t/graylog-api-browser-points-to-local-ip-instead-of-configured-external-url/17085/3) is : https://monitoring. + ${MACHINE_FQDN} + /grafana/api/api-browser/global/index.html

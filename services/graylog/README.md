# Graylog

## configuration files - currently not in use

Downloaded by executing

```console
wget https://raw.githubusercontent.com/Graylog2/graylog-docker/3.0/config/graylog.conf
wget https://raw.githubusercontent.com/Graylog2/graylog-docker/3.0/config/log4j2.xml
```


## testing

1. Create a GELF UDP INPUT
2. Show incoming messages
3. Send a message following:

```console
echo -n '{ "version": "1.1", "host": "example.org", "short_message": "A short message", "level": 5, "_some_info": "foo" }' | nc -w0 -u localhost 12201
```

## configure docker daemon to re-direct to gelf address

This needs to be added to /etc/docker/daemon.json

```json
    "log-driver": "gelf",
    "log-opts": {
      "gelf-address": "udp://127.0.0.1:12201"
    }
```

Restart the docker daemon after the modifications.

**Note:** docker logs command relies on the fact that logs are in json mode. Also the Portainer seems to show some error messages because of this change.
Maybe a look at logspout is worthwhile if we want to keep the docker logs functionality.
Needs to be done on all docker engines in the cluster.

## configuring simcore-stream to get all messages coming from the simcore-stack

done using Field **container_name** and Type **match regular expression** with Value ^simcore_.*
**Note:** this will fail with containers created by the sidecar.

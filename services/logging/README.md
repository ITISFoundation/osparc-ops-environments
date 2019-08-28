# Graylog

## configuration files

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

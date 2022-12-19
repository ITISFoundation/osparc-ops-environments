# Traefik stack

Stack to deploy a [Traefik v2](https://docs.traefik.io/) service to be used as reverse proxy and secure entrypoint.
By default the stack can create its own self-signed certificate for development, or use valid certificates for production.

By default Traefik opens a http (80) port and a https (443) port. Also a dashboard is available on port 8080.

## Status

### Features

- Allow usage of self-signed certificate
- Allow usage of valid certificates

### Upcoming

- Automate usage of let's encrypt to auto-generate certificates

## Usage

edit [.env](.env)

```console
MACHINE_FQDN=*.osparc.local # Replace with the wanted host name
```

**Note:** The machine fully qualified domain name may be set in the host machine in the host file (__C:\Windows\System32\drivers\etc\hosts__ or __/etc/hosts__) for local development.

### Create password
To create user:password pair, it's possible to use this command:
```
docker run --rm --entrypoint htpasswd registry:2 -nb user password | sed -e s/\\$/\\$\\$/g
echo $(htpasswd -nb user password) | sed -e s/\\$/\\$\\$/g
```

### local deployment with self-signed certificate

```console
make help
make create-certificates
make up
make info
```

### production deployment using valid certificates for production

1. copy your certificates and key to secrets/domain.crt, secrets/domain.key

    ```console
    make help
    make up
    make info
    ```

### example configuration of a service that gets reverse-proxied

```console
make create-certificates
make up
cd tests
make up
```

Then open [https://osparc.local/whoami](https://osparc.local/whoami)

## Debugging

### Serving default certificates after restoring traefik volume

By default, when you restore the volume, the file /letsencrypt/acme.json inside of the volume will not have the good permissions. You need to connect inside of the container and to run
```
chmod 600 letsencrypt/acme.json
```
And then restart traefik.

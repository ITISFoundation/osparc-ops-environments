# portus stack

Stack to deploy a secure [portus](http://port.us.org/) service with a [docker registry](https://docs.docker.com/registry/) v2 and a [clair security scanner](https://coreos.com/clair/docs/latest/).
By default the stack can create its own self-signed certificates for development usage. Valid certificates are obviously a better choice.

## Dependencies

a S3 storage is necessary (such as minio [services/minio](services/minio)) as backend to the docker registry.

## Configuration

edit [.env](.env)

```console
MACHINE_FQDN=devel.io # The machine Fully-Qualified-Domain-Name (FQDN), must be accessible from the host computer
DATABASE_PASSWORD=portus # password to Database backend to Portus
SECRET_KEY_BASE=b494a25faa8d22e430e843e220e424e10ac84d2ce0e64231f5b636d21251eb6d267adb042ad5884cbff0f3891bcf911bdf8abb3ce719849ccda9a4889249e5c2
PORTUS_PASSWORD=12345678 # password to database backend of Portus
S3_ACCESSKEY=12345678 # access key to S3 backend
S3_SECRETKEY=12345678 # secret key to S3 backend
S3_ENDPOINT=devel.io:30000 # endpoint to S3 backend
S3_REGISTRY_BUCKET=devel.registry.io # bucket in S3 backend where registry data is saved
```

**IMPORTANT:** the S3 backend **MUST** have the bucket already created or the registry fails (this is a bug from Docker Registry)

```console
cd ../minio
make up
```

### local usage

```console
make help
make up-local
make info
```

Initial Portus configuration:

1. Update the host system host file to redirect the FQDN to the local IP address: see __make install-full-qualified-domain-name__
2. go to you S3 frontend according to __S3_ENDPOINT__: [http://127.0.0.1:30000](http://127.0.0.1:30000) (default credentials __S3_ACCESSKEY__/__S3_SECRETKEY__)
3. create a bucket according to __S3_REGISTRY_BUCKET__
4. go to frontend according to __MACHINE_FQDN__: [https://devel.io](https://devel.io)
5. create the base admin account
6. connect portus to the registry using Hostname __MACHINE_FQDN__ and check __Use SSL__, press Save

Registry testing:

 1. In case self-signed certificates were used, execute __make install-root-certificate__, restart the docker engine
 2. Execute the code below in a shell. This will push the docker image to the registry. It will be visible in Portus UI after a few seconds.

    ```console
    docker pull busybox:latest
    docker tag busybox:latest devel.io/busybox:latest
    docker login devel.io # use credentials defined in Portus
    docker push devel.io/busybox:latest
    ```

### deployment using valid certificates

1. copy your certificates and key to secrets/portus.crt, secrets/portus.key

    ```console
    make help
    make up
    make info
    ```

2. then follow the same procedure as for local development

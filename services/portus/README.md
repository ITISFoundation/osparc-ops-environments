# portus stack

Stack to deploy portus service and all agents (one per node)

- [Portus](http://port.us.org/)

## Usage

```console
make help
make up
make info
make down
```

Available web front-ends when deployed in localhost:

- portus UI: [https://127.0.0.1:3000](https://127.0.0.1:3000)     (default credentials admin/adminadmin)

## Using a self-signed certificate

### create certificates (source [here](https://www.objectif-libre.com/en/blog/2018/06/11/self-hosting-a-secure-docker-registry-with-portus/))

- We need a certificate authority (CA), so we created a random key (rootca.key) and used it to generate a certificate (rootca.crt) valid for 1024 days.
- We need a private key for portus, so we generated a random one.
- Then we created a certificate signing request and used it to create our portus certificate using the “extfile.cnf”.

```console
echo "subjectAltName = IP:<YOUR_IP>" > extfile.cnf #You can use DNS:domain.tld too
openssl genrsa -out secrets/rootca.key 2048 -nodes
openssl req -x509 -new -nodes -key secrets/rootca.key \
 -subj "/C=US/ST=CA/O=Acme, Inc." \
 -sha256 -days 1024 -out secrets/rootca.crt
openssl genrsa -out secrets/portus.key 2048
openssl req -new -key secrets/portus.key -out secrets/portus.csr \
 -subj "/C=US/ST=CA/O=Acme, Inc./CN=<YOUR_IP>"
openssl x509 -req -in secrets/portus.csr -CA secrets/rootca.crt -extfile \
 extfile.cnf -CAkey secrets/rootca.key -CAcreateserial \
 -out secrets/portus.crt -days 500 -sha256
```

*Note:* Replace <YOUR_IP> with the host IP

### add the CA certificate to the docker engine (source [here](https://hackernoon.com/create-a-private-local-docker-registry-5c79ce912620))

```console
mkdir -p /etc/docker/certs.d/<YOUR_IP>
cd /secrets
sudo cp /certs/rootCA.crt /etc/docker/certs.d/<YOUR_IP>/ca.crt
sudo service docker reload
```

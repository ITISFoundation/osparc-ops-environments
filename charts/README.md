# Welcome to our Kubernetes deployment

## Installing requirements

#### kube

Follow the insructions here: https://kubernetes.io/de/docs/tasks/tools/install-kubectl/

#### kind (for local deployment)

```bash
# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
# For ARM64
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

source: https://kind.sigs.k8s.io/docs/user/quick-start

#### helm

Follow the instructions here: https://helm.sh/docs/intro/install/

Install the helm-diff plugin: `helm plugin install https://github.com/databus23/helm-diff`

`via https://doc.traefik.io/traefik/user-guides/crd-acme/#ingressroute-definition`
Install traefik-v3 CRDs: `kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.1/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml`

`via https://doc.traefik.io/traefik/user-guides/crd-acme/#ingressroute-definition`
Install traefik-v3 RBAC: `kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.1/docs/content/reference/dynamic-configuration/kubernetes-crd-rbac.yml`

#### helmfile

If you have a different OS / architecture, pick a different link from [release artifacts](https://github.com/helmfile/helmfile/releases)

```bash
wget https://github.com/helmfile/helmfile/releases/download/v0.165.0/helmfile_0.165.0_linux_amd64.tar.gz
tar -xzf helmfile_0.165.0_linux_amd64.tar.gz
mv helmfile /usr/local/bin
chmod +x /usr/local/bin/helmfile
helmfile init
```

## Running k8s cluster locally

Use `./local-k8s.Makefile` targets.

## FAQ

#### helmfile apply fails. Files cannot be rendered properly. How to debug?

Use `helmfile-tempalate` target with `--debug` argument. Example:

```bash
make helmfile-template HELMFILE_EXTRA_ARGS='--selector app=victoria-logs --debug'
```

This will print generated files even if format is not valid. Having this text can help you identify what is wrong.

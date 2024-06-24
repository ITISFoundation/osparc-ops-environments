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

```bash
cd ./osparc-ops-environments
./scripts/create_local_k8s_cluster.bash
```

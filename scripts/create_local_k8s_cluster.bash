#!/bin/bash

set -e
set -o nounset
set -o pipefail

THIS_SCRIPT_DIR=$(dirname "$0")
KIND_CONFIG_FILE="$THIS_SCRIPT_DIR/kind_config.yaml"
KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-osparc-cluster}"

if ! command -v kind &> /dev/null; then
    echo "Error: kind is not installed. Please install kind and try again."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed. Please install kubectl and try again."
    exit 1
fi

if kind get clusters | grep -q "^$KIND_CLUSTER_NAME$"; then
        echo "A cluster '$KIND_CLUSTER_NAME' is already up."
        exit 0
fi

if [[ ! -f "$KIND_CONFIG_FILE" ]]; then
    echo "Error: Configuration file $KIND_CONFIG_FILE not found."
    exit 1
fi

#
# create a k8s cluster
#

echo "Creating a local Kubernetes cluster named '$KIND_CLUSTER_NAME' using configuration from '$KIND_CONFIG_FILE'..."

kind create cluster --config "$KIND_CONFIG_FILE" --name "$KIND_CLUSTER_NAME"

#
# install Calico network CNI
#

# https://docs.tigera.io/calico/3.30/getting-started/kubernetes/kind

echo "Installing Calico network CNI ..."

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/operator-crds.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/tigera-operator.yaml

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/custom-resources.yaml

echo "Waiting for Calico pods to start..."
while ! kubectl get pods -A -l k8s-app=calico-node 2>/dev/null | grep -q "Running"; do sleep 1; done

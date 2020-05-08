# How-to purge docker registry

This document explains the steps necessary to purge a docker registry.

## Dependencies

- curl
- jq
- ./scripts/docker-registry-curl.bash

## Usage


0. Restart the registry in read-only mode using the following flag
    
    ```console
    REGISTRY_STORAGE_MAINTENANCE_READONLY = {"enabled":true}
    ```

1. Listing repositories, images, etc...

    ```console
    export DOCKER_USERNAME=YourUserName
    export DOCKER_PASSWORD=YourPassword
    export REGISTRY_URL=YourRegistry
    export REPO=YourRepo

    # list the repositories
    ./scripts/docker-registry-curl.bash ${REGISTRY_URL}/v2/_catalog | jq

    # list the tags in one repository
    ./scripts/docker-registry-curl.bash ${REGISTRY_URL}/v2/${REPO}/tags/list | jq
    ```

2. Delete the images through the registry REST API

    ``` console
    export DOCKER_USERNAME=YourUserName
    export DOCKER_PASSWORD=YourPassword
    export REGISTRY_URL=YourRegistry
    export REPO=YourRepo

    # get the image ETAG
    ETAG=$(./scripts/docker-registry-curl.bash --head -H "Accept: application/vnd.docker.distribution.manifest.v2+json" ${REGISTRY_URL}/v2/${REPO}/manifests/${TAG} | grep -E etag: | cut --delimiter=\" --fields=2)
    # delete the image and receive a 202 when done
    ./scripts/docker-registry-curl.sh -X DELETE "${REGISTRY_URL}/v2/${REPO}/manifests/${ETAG}"
    ```

3. Run the garbage collector in the registry container

    ```console
    docker exec RegistryID bin/registry garbage-collect /etc/docker/registry/config.yml -m
    ```

4. To delete entire repository the last step is to enter the S3 storage and remove the folder in ${S3_URL}/{S3_BUCKET}/docker/registry/v2/repositories/${REPO}
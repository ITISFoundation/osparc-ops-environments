# Deployment workflow

# Deploy development

## Deploy docker swarm

1. login to the cluster MANAGER machine (defines the system environ, e.g. master, staging, production)
2. create a swarm
```console
docker swarm init
```
3. for each cluster worker/manager node
```console
ssh MACHINE "docker swarm-join TOKEN"
```

## develop an environ snapshot

1. on the MANAGER machine
2. clone **INTERNAL** osparc-ops, create a branch (all the credentials will be saved at the end, **DO NOT** push configuration passwords, certificates to Github!, create a fork on a controlled Git repo!)

    ```console
    git clone INTERNAL/osparc-ops.git
    cd osparc-ops
    git checkout -b environ_SYSTEM
    ```

3. deploy Portainer  
see [services/portainer/README.md](services/portainer/README.md)

    ```console
    cd services/portainer
    # configure
    make up
    ```

4. deploy Graylog stack (logging)  
see [services/graylog/README.md](services/graylog/README.md)

    ```console
    cd services/graylog
    # configure
    make up
    ```

5. deploy monitoring stack (Prometheus)  
see [services/monitoring/README.md](services/monitoring/README.md)

    ```console
    cd services/monitoring
    # configure
    make up
    ```

6. deploy minio stack (S3)  
see [services/minio/README.md](services/minio/README.md)

    ```console
    cd services/minio
    # configure
    make up
    ```

7. deploy deployment-agent stack (auto-deployer for simcore stack)  
see [services/deployment-agent/README.md](services/deployment-agent/README.md)

    ```console
    cd services/deployment-agent
    # configure 
    make up
    ```

8. edit [repo.config](repo.config)
9. Push all the necessary changes to the **controlled and internal** git repository

## Normal deployment

1. This implies the swarm is already created on the cluster (if not deploy it)
2. On the local machine
3. clone **INTERNAL** osparc-ops

    ```console
    git clone INTERNAL/osparc-ops.git
    cd osparc-ops
    git checkout environ_SYSTEM
    ```

4. Auto deploy all the components to the MANAGER

    ```console
    bash scripts/deploy.sh
    ```

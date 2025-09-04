## Starting a cluster

Make sure all nodes have joined the cluster before using it. Otherwise, number of replicas in quorum queues might be affected. Say, you have a cluster of 3 nodes. You connect to cluster before the 3rd node join it. Your quorum queue would end up with only 2 replicas and will be broken once, 1 node (of 2 nodes holding the replicas of the queue) goes down.

## Updating rabbitmq.conf / advanced.config (zero-downtime)

We do not support this automated (except starting from scratch with empty volumes). But manually this can be achieved in case needed. `rabbitmq.conf` and `advanced.config` changes take effect after a node restart. This can be performed with zero-downtime when RabbitMQ is clustered (have multiple nodes). This can be achieved by stopping and starting rabbitmq nodes one by one
* `docker exec -it <container-id> bash`
* (inside container) `rabbitmqctl stop_app` and wait some time until node is stopped (can be seen in management ui)
* (inside container) `rabbitmqctl start_app`

Source: https://www.rabbitmq.com/docs/next/configure#config-changes-effects

## How to add / remove nodes

The only supported way, is to completely shutdown the cluster (docker stack and most likely rabbit node volumes) and start brand new.

With manual effort this can be done on the running cluster, by adding 1 more rabbit node manually (as a separate docker stack or new service) and manually executing rabbitmqctl commands (some hints can be found here https://www.rabbitmq.com/docs/clustering#creating)

## Autoscaling

Not supported at the moment.

## Enable node Maintenance mode

1. Get inside container's shell (`docker exec -it <container-id> bash`)
2. (Inside container) execute `rabbitmq-upgrade drain`

Source: https://www.rabbitmq.com/docs/upgrade#maintenance-mode

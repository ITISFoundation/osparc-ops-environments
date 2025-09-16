## Starting a cluster

Make sure all nodes have joined the cluster before using it. Otherwise, number of replicas in quorum queues might be affected. Say, you have a cluster of 3 nodes. You connect to cluster before the 3rd node join it. Your quorum queue would end up with only 2 replicas and will be broken once, 1 node (of 2 nodes holding the replicas of the queue) goes down.

## Updating a cluster

Perform update one node at a time. Never update all nodes at the same time (this may break cluster)! Follow instructions from official documentation https://www.rabbitmq.com/docs/upgrade#rolling-upgrade.

## Graceful shutdown

Shutdown nodes one by one gracefully. Wait until the nodes is stopped and leaves the cluster. Then remove next node. When starting cluster, start nodes **in the reverse order**! For example, if you shutdown node01, then node02 and lastly node03, first start node03 then node02 and finally node01.

If all Nodes were shutdown simultaneously, then you will see mnesia tables errors in node's logs. Restarting node solves the issue. Documentation also mentions force_boot CLI command in this case (see https://www.rabbitmq.com/docs/man/rabbitmqctl.8#force_boot)

## How to add / remove nodes

The only supported way, is to completely shutdown the cluster (docker stack and most likely rabbit node volumes) and start brand new.

With manual effort this can be done on the running cluster, by adding 1 more rabbit node manually (as a separate docker stack or new service) and manually executing rabbitmqctl commands (some hints can be found here https://www.rabbitmq.com/docs/clustering#creating)

## Updating rabbitmq.conf / advanced.config (zero-downtime)

We do not support this automated (except starting from scratch with empty volumes). But manually this can be achieved in case needed. `rabbitmq.conf` and `advanced.config` changes take effect after a node restart. This can be performed with zero-downtime when RabbitMQ is clustered (have multiple nodes). This can be achieved by stopping and starting rabbitmq nodes one by one
* `docker exec -it <container-id> bash`
* (inside container) `rabbitmqctl stop_app` and wait some time until node is stopped (can be seen in management ui)
* (inside container) `rabbitmqctl start_app`

Source: https://www.rabbitmq.com/docs/next/configure#config-changes-effects

## Enable node Maintenance mode

1. Get inside container's shell (`docker exec -it <container-id> bash`)
2. (Inside container) execute `rabbitmq-upgrade drain`

Source: https://www.rabbitmq.com/docs/upgrade#maintenance-mode

#### Troubleshooting
mnesia errors after all rabbit nodes (docker services) restart:
* https://stackoverflow.com/questions/60407082/rabbit-mq-error-while-waiting-for-mnesia-tables

official documentation mentioning restart scenarios
* https://www.rabbitmq.com/docs/clustering#restarting-schema-sync

all (3) cluster nodes go down simultaneosuly, cluster is broken:
* https://groups.google.com/g/rabbitmq-users/c/owvanX2iSqA

## Autoscaling

Not supported at the moment.

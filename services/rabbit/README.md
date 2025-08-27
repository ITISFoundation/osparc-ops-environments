## Updating rabbitmq.conf / advanced.config (zero-downtime)

rabbitmq.conf and advanced.config changes take effect after a node restart. This can be performed with zero-downtime when RabbitMQ is clustered (have multiple nodes). This can be achieved by stopping and starting rabbitmq nodes one by one
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

## Rotating erlang cookie (zero-downtime)

In our case, a full stop of rabbit cluster is required (it means downtime). Nodes shall be started from scratch with a new erlang cookie. If zero-downtime update is an absolute must, blue-green deployments is a way to go according to core developers (see sources)

Source: https://github.com/rabbitmq/rabbitmq-server/discussions/14391

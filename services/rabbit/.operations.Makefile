#
# Variables
#

NODE_IXS := $(shell seq 1 $(NODE_COUNT))

LOAD_BALANCER_STACK_NAME := rabbit-loadbalancer

#
# Helpers
#

define create_rabbit_node_name
rabbit-node0$(1)
endef

#
# Cluster level
#

up: start-cluster

start-cluster: start-all-nodes start-loadbalancer

down:
	@$(error This operation may break cluster. Perform it per component)

#
# Load Balancer
#

start-loadbalancer: docker-compose.loadbalancer.yml
	@docker stack deploy -c $< $(LOAD_BALANCER_STACK_NAME)

update-loadbalancer: start-loadbalancer

stop-loadbalancer:
	@docker stack rm $(LOAD_BALANCER_STACK_NAME)

#
# Rabbit all Nodes together
#

start-all-nodes: guard-NODE_COUNT $(foreach i,$(NODE_IXS),start-node0$(i))

update-all-nodes:
	@$(error Updating all nodes at the same time may break cluster. Update one node at a time)

stop-all-nodes:
	@$(error Stopping all nodes at the same time may break cluster. Update one node at a time)

#
# Rabbit Node level
#

start-node0%: docker-compose.node0%.yml
	@STACK_NAME=$(call create_rabbit_node_name,$*); \
	if docker stack ls --format '{{.Name}}' | grep --silent "$$STACK_NAME"; then \
		echo "Rabbit Node $* is already running, skipping"; \
	else \
		echo "Starting Rabbit Node $* ..."; \
		docker stack deploy -c $< $(call create_rabbit_node_name,$*)
	fi

update-node0%: docker-compose.node0%.yml
	@docker stack deploy --detach=false -c $< $(call create_rabbit_node_name,$*)

stop-node0%: docker-compose.node0%.yml
	@docker stack rm --detach=false $(call create_rabbit_node_name,$*)

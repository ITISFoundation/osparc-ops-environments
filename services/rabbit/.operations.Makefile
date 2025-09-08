#
# Variables
#

LOAD_BALANCER_STACK_NAME := rabbit-loadbalancer

MAKEFLAGS += --no-print-directory

#
# Helpers
#

define create_rabbit_node_name
rabbit-node0$(1)
endef

guard-positive-single-digit-integer-NODE_COUNT: guard-NODE_COUNT
	@if ! echo "$(NODE_COUNT)" | grep --quiet --extended-regexp '^[1-9]$$'; then \
		echo NODE_COUNT must be a positive single digit integer; \
		exit 1; \
	fi

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

start-loadbalancer: .stack.loadbalancer.yml
	@docker stack deploy --with-registry-auth --prune --compose-file $< $(LOAD_BALANCER_STACK_NAME)

update-loadbalancer: start-loadbalancer

stop-loadbalancer:
	@docker stack rm $(LOAD_BALANCER_STACK_NAME)

#
# Rabbit all Nodes together
#

.start-all-nodes: guard-positive-single-digit-integer-NODE_COUNT
	@i=1; \
	while [ $$i -le $(NODE_COUNT) ]; do \
		$(MAKE) start-node0$$i; \
		i=$$((i + 1)); \
	done

start-all-nodes: .env
	@source $<; \
	$(MAKE) .start-all-nodes NODE_COUNT=$$RABBIT_CLUSTER_NODE_COUNT

update-all-nodes:
	@$(error Updating all nodes at the same time may break cluster. Update one node at a time)

stop-all-nodes:
	@$(error Stopping all nodes at the same time may break cluster.)

#
# Rabbit Node level
#

start-node0%: .stack.node0%.yml
	@STACK_NAME=$(call create_rabbit_node_name,$*); \
	if docker stack ls --format '{{.Name}}' | grep --silent "$$STACK_NAME"; then \
		echo "Rabbit Node $* is already running, skipping"; \
	else \
		echo "Starting Rabbit Node $* ..."; \
		docker stack deploy --with-registry-auth --prune --compose-file $< $(call create_rabbit_node_name,$*); \
	fi

update-node0%: .stack.node0%.yml
	@docker stack deploy --detach=false --with-registry-auth --prune --compose-file $< $(call create_rabbit_node_name,$*)

stop-node0%: .stack.node0%.yml
	@docker stack rm --detach=false $(call create_rabbit_node_name,$*)

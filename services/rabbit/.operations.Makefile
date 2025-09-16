#
# Variables
#

LOAD_BALANCER_STACK_NAME := rabbit-loadbalancer

MAKEFLAGS += --no-print-directory

#
# Helpers
#

define create_node_stack_name
rabbit-node0$(1)
endef

validate-NODE_COUNT: guard-NODE_COUNT
	@if ! echo "$(NODE_COUNT)" | grep --quiet --extended-regexp '^[1-9]$$'; then \
		echo NODE_COUNT must be a positive single digit integer; \
		exit 1; \
	fi

validate-node-ix0%: .env
	@if ! echo "$*" | grep --quiet --extended-regexp '^[1-9]$$'; then \
		echo "Node index $* must be a positive single digit integer"; \
		exit 1; \
	fi

	@set -o allexport; . $<; set +o allexport; \
	if [ "$*" -lt 1 ] || [ "$*" -gt "$$RABBIT_CLUSTER_NODE_COUNT" ]; then \
		echo "Node index $* is out of range 1..$$RABBIT_CLUSTER_NODE_COUNT"; \
		exit 1; \
	fi

#
# Cluster level
#

### Note: up operation is called by CI automatically
###       it must NOT deploy stacks if they are already running
###       to avoid breaking existing cluster (stopping all nodes at once)
up: start-cluster

down: stop-cluster

start-cluster: start-all-nodes start-loadbalancer

update-cluster stop-cluster:
	@$(error This operation may break cluster. Check README for details.)

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

.start-all-nodes: validate-NODE_COUNT
	@i=1; \
	while [ $$i -le $(NODE_COUNT) ]; do \
		$(MAKE) start-node0$$i; \
		i=$$((i + 1)); \
	done

start-all-nodes: .env
	@source $<; \
	$(MAKE) .start-all-nodes NODE_COUNT=$$RABBIT_CLUSTER_NODE_COUNT

update-all-nodes:
	@$(error Updating all nodes at the same time may break the cluster \
	as it may restart (i.e. stop) all nodes at the same time. \
	Update one node at a time)

stop-all-nodes:
	@$(error Stopping all nodes at the same time breaks the cluster. \
	Update one node at a time. \
	Read more at https://groups.google.com/g/rabbitmq-users/c/owvanX2iSqA/m/ZAyRDhRfCQAJ)

#
# Rabbit Node level
#

start-node0%: validate-node-ix0% .stack.node0%.yml
	@STACK_NAME=$(call create_node_stack_name,$*); \
	if docker stack ls --format '{{.Name}}' | grep --silent "$$STACK_NAME"; then \
		echo "Rabbit Node $* is already running, skipping"; \
	else \
		echo "Starting Rabbit Node $* ..."; \
		docker stack deploy --with-registry-auth --prune --compose-file $(word 2,$^) $(call create_node_stack_name,$*); \
	fi

update-node0%: validate-node-ix0% .stack.node0%.yml
	@docker stack deploy --detach=false --with-registry-auth --prune --compose-file $(word 2,$^) $(call create_node_stack_name,$*)

stop-node0%: validate-node-ix0%
	@docker stack rm --detach=false $(call create_node_stack_name,$*)

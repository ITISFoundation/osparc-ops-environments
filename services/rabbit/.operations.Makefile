#
# Variables
#

LOAD_BALANCER_STACK_NAME := rabbit-loadbalancer

MAKEFLAGS += --no-print-directory

NODE_STATE_CHANGE_WAIT_TIME ?= 20s

#
# Helpers
#

define create_node_stack_name
rabbit-node0$(1)
endef

# start and stop order shall be reversed. So, if nodes are shutdown in order 3,2,1
# they should be started in order 1,2,3 to ensure proper cluster formation.
# Check README for details.
define node_start_order_ixs
$(shell seq 1 $(1))
endef

define node_stop_order_ixs
$(shell seq $(1) -1 1)
endef

define wait_cluster_to_stabilize
echo "Waiting $(1) for cluster to stabilize ..."; \
sleep $(1)
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

confirm-stop-cluster: guard-optional-bool-FORCE_CONFIRM
	@$(call confirm_action,Are you sure you want to stop Rabbit Cluster?,yes,$(FORCE_CONFIRM))

.PHONY: prune-docker-stack-lb-configs
prune-docker-stack-lb-configs:
	@# default implementation does not work. We override it
	@# (use LOAD_BALANCER_STACK_NAME instead of STACK_NAME)
	@for id in $$(docker config ls --filter "label=com.docker.stack.namespace=$(LOAD_BALANCER_STACK_NAME)" --format '{{.ID}}'); do \
	    docker config rm "$$id" >/dev/null 2>&1 || true; \
	done

#
# Cluster level
#

### Note: up operation is called by CI automatically
###       it must NOT deploy stacks if they are already running
###       to avoid breaking existing cluster (stopping all nodes at once)
up up-master up-dalco up-aws up-local up-public: start-cluster

down: stop-cluster
	@: # empty instruction. Necessary to override default behavior

start-cluster: start-all-nodes start-loadbalancer ## start rabbit cluster (all nodes + load balancer)

update-cluster: update-all-nodes update-loadbalancer  ## update rabbit cluster (all nodes + load balancer)

stop-cluster: confirm-stop-cluster stop-loadbalancer stop-all-nodes
stop-cluster: ## gracefully stop rabbit cluster (all nodes + load balancer)

#
# Load Balancer
#

start-loadbalancer: .stack.loadbalancer.yml prune-docker-stack-lb-configs ## start rabbit cluster load balancer
	@docker stack deploy --detach=false --with-registry-auth --prune --compose-file $< $(LOAD_BALANCER_STACK_NAME)

update-loadbalancer: start-loadbalancer ## update rabbit cluster load balancer

stop-loadbalancer:  ## stop rabbit cluster load balancer
	@docker stack rm $(LOAD_BALANCER_STACK_NAME)

#
# Rabbit all Nodes together
#

.start-all-nodes: validate-NODE_COUNT
	@for i in $(call node_start_order_ixs,$(NODE_COUNT)); do \
		$(MAKE) start-node0$$i; \
	done

start-all-nodes: .env  ## start all rabbit cluster nodes
	@source $<; \
	$(MAKE) .start-all-nodes NODE_COUNT=$$RABBIT_CLUSTER_NODE_COUNT

update-all-nodes:  ## update all rabbit cluster nodes
	@$(error Not implemented. Updating all nodes at the same time may break the cluster. \
	Update one node at a time. Check README for details.)

.stop-all-nodes: validate-NODE_COUNT
	@for i in $(call node_stop_order_ixs,$(NODE_COUNT)); do \
		$(MAKE) stop-node0$$i; \
	done

stop-all-nodes: .env  ## gracefully stop all rabbit cluster nodes
	@source $<; \
	$(MAKE) .stop-all-nodes NODE_COUNT=$$RABBIT_CLUSTER_NODE_COUNT

#
# Rabbit Node level
#

start-nodeINDEX:  ## start rabbit cluster node <INDEX> (e.g. `make start-node01` to start node 1)
start-node0%: validate-node-ix0% .stack.node0%.yml
	@STACK_NAME=$(call create_node_stack_name,$*); \
	if docker stack ls --format '{{.Name}}' | grep --silent "$$STACK_NAME"; then \
		echo "Rabbit Node $* is already running, skipping"; \
	else \
		echo "Starting Rabbit Node $* ..."; \
		docker stack deploy --detach=false --with-registry-auth --prune --compose-file $(word 2,$^) $$STACK_NAME; \
		$(call wait_cluster_to_stabilize,$(NODE_STATE_CHANGE_WAIT_TIME)); \
	fi

update-nodeINDEX:  ## update rabbit cluster node <INDEX> (e.g. `make update-node01` to update node 1)
update-node0%: validate-node-ix0% .stack.node0%.yml
	@STACK_NAME=$(call create_node_stack_name,$*); \
	docker stack deploy --detach=false --with-registry-auth --prune --compose-file $(word 2,$^) $$STACK_NAME

stop-nodeINDEX:  ## stop rabbit cluster node <INDEX> (e.g. `make stop-node01` to stop node 1)
stop-node0%: validate-node-ix0%
	@STACK_NAME=$(call create_node_stack_name,$*); \
	if docker stack ls --format '{{.Name}}' | grep --silent "$$STACK_NAME"; then \
		echo "Stopping Rabbit Node $* ..."; \
		docker stack rm --detach=false $$STACK_NAME; \
		$(call wait_cluster_to_stabilize,$(NODE_STATE_CHANGE_WAIT_TIME)); \
	else \
		echo "Rabbit Node $* is not running, skipping"; \
		exit 0; \
	fi

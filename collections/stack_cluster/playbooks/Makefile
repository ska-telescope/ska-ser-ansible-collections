PRIVATE_VARS ?= private_vars.yml
INVENTORY_FILE ?= ./inventory_cluster
EXTRA_VARS ?=
COLLECTIONS_PATHS ?= ./collections

.DEFAULT_GOAL := help

# define overides for above variables in here
-include PrivateRules.mak

ANSIBLE_COLLECTIONS_PATHS := $(COLLECTIONS_PATHS):~/.ansible/collections:/usr/share/ansible/collections
STACK_CLUSTER_PLAYBOOKS := $(COLLECTIONS_PATHS)/ansible_collections/ska_cicd/stack_cluster/playbooks
DOCKER_PLAYBOOKS := $(COLLECTIONS_PATHS)/ansible_collections/ska_cicd/docker_base/playbooks


vars:  ## Variables
	@echo "Current variable settings:"
	@echo "PRIVATE_VARS=$(PRIVATE_VARS)"
	@echo "INVENTORY_FILE=$(INVENTORY_FILE)"
	@echo "EXTRA_VARS=$(EXTRA_VARS)"
	@echo "ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS)"
	@echo "STACK_CLUSTER_PLAYBOOKS=$(STACK_CLUSTER_PLAYBOOKS)"
	@echo "DOCKER_PLAYBOOKS=$(DOCKER_PLAYBOOKS)"

uninstall:  # uninstall collections
	rm -rf $(COLLECTIONS_PATHS)/ansible_collections/*

install:  ## Install dependent ansible collections
	ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS) \
	ANSIBLE_COLLECTIONS_PATH=$(ANSIBLE_COLLECTIONS_PATHS) \
	ansible-galaxy collection install \
	-r requirements.yml -p ./collections

reinstall: uninstall install ## reinstall collections

all: build ## call build

build: build_hosts build_common build_docker ## build hosts and then apply common and docker

clean_nodes:  ## destroy out nodes
	[ ! -e $(PRIVATE_VARS) ] || touch $(PRIVATE_VARS)
	ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS) \
	ANSIBLE_COLLECTIONS_PATH=$(ANSIBLE_COLLECTIONS_PATHS) \
	ansible-playbook -e @$(PRIVATE_VARS) \
					 --extra-vars="$(EXTRA_VARS)" \
					 -i $(STACK_CLUSTER_PLAYBOOKS)/inventory \
					 $(STACK_CLUSTER_PLAYBOOKS)/remove-cluster-infra.yml

clean_hosts: clean_nodes ## destroy hosts (alias for nodes)

clean_all: clean_hosts  ## destroy nodes and security group/s

clean: clean_all  ## call clean_all

build_nodes:  ## build the nodes (VMs)
	[ ! -e $(PRIVATE_VARS) ] || touch $(PRIVATE_VARS)
	ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS) \
	ANSIBLE_COLLECTIONS_PATH=$(ANSIBLE_COLLECTIONS_PATHS) \
	ansible-playbook -e @$(PRIVATE_VARS) \
					 --extra-vars="$(EXTRA_VARS)" \
					 -i $(STACK_CLUSTER_PLAYBOOKS)/inventory \
					 $(STACK_CLUSTER_PLAYBOOKS)/cluster-infra.yml \
	--extra-vars="inventory_file=../../../../$(INVENTORY_FILE)"

check:  ## check that filesystems are there
	ansible -i ./$(INVENTORY_FILE) cluster \
	                         -m shell -a 'df; lsblk'

build_hosts: build_nodes ## build hosts (only)

build_common:  ## apply the common roles
	[ ! -e $(PRIVATE_VARS) ] || touch $(PRIVATE_VARS)
	ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS) \
	ANSIBLE_COLLECTIONS_PATH=$(ANSIBLE_COLLECTIONS_PATHS) \
	ansible-playbook  -e @$(PRIVATE_VARS) \
					  -i $(INVENTORY_FILE) $(STACK_CLUSTER_PLAYBOOKS)/common.yml

build_docker:  ## apply the docker roles
	[ ! -e $(PRIVATE_VARS) ] || touch $(PRIVATE_VARS)
	ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS) \
	ANSIBLE_COLLECTIONS_PATH=$(ANSIBLE_COLLECTIONS_PATHS) \
	ansible-playbook  -e @$(PRIVATE_VARS) \
					  -i $(INVENTORY_FILE) $(DOCKER_PLAYBOOKS)/docker.yml

lint: install ## Lint check playbook
	ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS) \
	ANSIBLE_COLLECTIONS_PATH=$(ANSIBLE_COLLECTIONS_PATHS) \
	ansible-lint $(STACK_CLUSTER_PLAYBOOKS)/cluster-infra.yml \
	  $(STACK_CLUSTER_PLAYBOOKS)/common.yml \
	  $(DOCKER_PLAYBOOKS)/docker.yml

restart:  ## Restart hosts
	[ ! -e $(PRIVATE_VARS) ] || touch $(PRIVATE_VARS)
	ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS) \
	ANSIBLE_COLLECTIONS_PATH=$(ANSIBLE_COLLECTIONS_PATHS) \
	ansible-playbook  -e @$(PRIVATE_VARS) \
					  -i $(STACK_CLUSTER_PLAYBOOKS)/inventory \
					  $(STACK_CLUSTER_PLAYBOOKS)/restart-hosts.yml


help:  ## show this help.
	@echo "make targets:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""; echo "make vars (+defaults):"
	@grep -E '^[0-9a-zA-Z_-]+ \?=.*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = " \\?\\= "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

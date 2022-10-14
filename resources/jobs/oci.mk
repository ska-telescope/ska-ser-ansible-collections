.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
INVENTORY_FILE ?= $(PLAYBOOKS_ROOT_DIR)/inventory.yml 

-include $(BASE_PATH)/PrivateRules.mak

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

vars:
	@echo "\033[36mOCI:\033[0m"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"

docker: check_hosts ## Install docker
	ansible-playbook ./ansible_collections/ska_collections/docker_base/playbooks/docker.yml \
	-i $(INVENTORY_FILE)\
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"
	
containerd: check_hosts ## Install containerd
	ansible-playbook ./ansible_collections/ska_collections/docker_base/playbooks/containerd.yml \
	-i $(INVENTORY_FILE) \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"
	
podman: check_hosts ## Install podman
	ansible-playbook ./ansible_collections/ska_collections/docker_base/playbooks/podman.yml \
	-i $(INVENTORY_FILE) \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

help: ## Show Help
	@echo "Oci targets - make playbooks oci <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


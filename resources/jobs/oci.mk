.DEFAULT_GOAL := help

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

docker: check_hosts ## Install docker
	ansible-playbook ./ansible_collections/ska_collections/docker_base/playbooks/docker.yml \
	-i $(PLAYBOOKS_ROOT_DIR)/inventory.yml \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"
	
containerd: check_hosts ## Install containerd
	ansible-playbook ./ansible_collections/ska_collections/docker_base/playbooks/containerd.yml \
	-i $(PLAYBOOKS_ROOT_DIR)/inventory.yml \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"
	
podman: check_hosts ## Install podman
	ansible-playbook ./ansible_collections/ska_collections/docker_base/playbooks/podman.yml \
	-i $(PLAYBOOKS_ROOT_DIR)/inventory.yml \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

help: ## Show Help
	@echo "OCI targets - make playbooks oci <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


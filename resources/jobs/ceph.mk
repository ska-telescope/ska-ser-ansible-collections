.DEFAULT_GOAL := help

V?=-vvv

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

install: check_hosts ## Install ceph
	@ansible-playbook ./ansible_collections/ska_collections/ceph/playbooks/install.yml \
	-i $(PLAYBOOKS_ROOT_DIR)/inventory.yml \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" $(V)

help: ## Show Help
	@echo "Ceph targets - make playbooks ceph <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
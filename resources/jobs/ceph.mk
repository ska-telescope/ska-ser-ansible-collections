.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

vars:
	@echo "\033[36mCeph:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"

install: check_hosts ## Install ceph
	@ansible-playbook ./ansible_collections/ska_collections/ceph/playbooks/install.yml \
	-i $(INVENTORY) \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

help: ## Show Help
	@echo "Ceph targets - make playbooks ceph <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
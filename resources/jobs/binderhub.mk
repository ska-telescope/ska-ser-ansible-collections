.PHONY: check_hosts vars install destroy help
.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
ANSIBLE_EXTRA_VARS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)/installation
PLAYBOOKS_DIR ?= ./ansible_collections/ska_collections/k8s/playbooks

-include $(BASE_PATH)/PrivateRules.mak

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

vars:
	@echo "\033[36mBinderhub:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"
	@echo "ANSIBLE_EXTRA_VARS=$(ANSIBLE_EXTRA_VARS)"

install: check_hosts ## Install Binderhub server
	ansible-playbook $(PLAYBOOKS_DIR)/binderhub.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

destroy: check_hosts ## Destroy Binderhub server
	ansible-playbook $(PLAYBOOKS_DIR)/binderhub_destroy.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

help: ## Show Help
	@echo "Binderhub targets - make playbooks binderhub <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

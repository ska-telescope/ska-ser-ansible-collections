.PHONY: check_hosts check_logging_secrets vars install destroy help
.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
ANSIBLE_EXTRA_VARS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)
PLAYBOOKS_DIR ?= ./ansible_collections/ska_collections/logging/playbooks
TESTS_DIR ?= ./ansible_collections/ska_collections/logging/tests

-include $(BASE_PATH)/PrivateRules.mak

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

vars:
	@echo "\033[36mLogging:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"

install: check_hosts ## Install elastic cluster
	ansible-playbook $(PLAYBOOKS_DIR)/install.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

destroy: check_hosts ## Destroy elastic cluster
	ansible-playbook $(PLAYBOOKS_DIR)/destroy.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

update-api-keys: check_hosts ## Create/invalidate elastic api-keys
	ansible-playbook $(PLAYBOOKS_DIR)/update-api-keys.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

list-api-keys: check_hosts ## List elastic api-keys
	ansible-playbook $(PLAYBOOKS_DIR)/list-api-keys.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

install-beats: check_hosts ## Install beats for log collection
	ansible-playbook $(PLAYBOOKS_DIR)/logging.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

destroy-beats: check_hosts ## Destroy beats for log collection
	ansible-playbook $(PLAYBOOKS_DIR)/destroy-logging.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

test-e2e: check_hosts ## Test elastic cluster
	ansible-playbook $(TESTS_DIR)/e2e/main.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

help: ## Show Help
	@echo "Logging targets - make playbooks logging <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
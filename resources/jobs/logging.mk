.PHONY: logging-check-hosts check_logging_secrets vars install destroy help
.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
ANSIBLE_EXTRA_VARS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)
PLAYBOOKS_DIR ?= ./ansible_collections/ska_collections/logging/playbooks
TESTS_DIR ?= ./ansible_collections/ska_collections/logging/tests

-include $(BASE_PATH)/PrivateRules.mak

logging-check-hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

logging-vars:
	@echo "\033[36mLogging:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"

logging-install: logging-check-hosts ## Install elastic cluster
	ansible-playbook $(PLAYBOOKS_DIR)/install.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

logging-destroy: logging-check-hosts ## Destroy elastic cluster
	ansible-playbook $(PLAYBOOKS_DIR)/destroy.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

logging-update-api-keys: logging-check-hosts ## Create/invalidate elastic api-keys
	ansible-playbook $(PLAYBOOKS_DIR)/update-api-keys.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

logging-list-api-keys: logging-check-hosts ## List elastic api-keys
	ansible-playbook $(PLAYBOOKS_DIR)/list-api-keys.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

logging-install-beats: logging-check-hosts ## Install beats for log collection
	ansible-playbook $(PLAYBOOKS_DIR)/logging.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

logging-destroy-beats: logging-check-hosts ## Destroy beats for log collection
	ansible-playbook $(PLAYBOOKS_DIR)/destroy-logging.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

logging-test: logging-check-hosts ## Test elastic cluster
	ansible-playbook $(TESTS_DIR)/logging.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

logging-help: ## Show Help
	@echo "Logging targets - make playbooks logging <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
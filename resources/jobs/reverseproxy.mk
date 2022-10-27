.PHONY: check_hosts vars install destroy help
.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
ANSIBLE_VAULT_EXTRA_ARGS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)
PLAYBOOKS_DIR ?= ./ansible_collections/ska_collections/instance_common/playbooks

-include $(BASE_PATH)/PrivateRules.mak

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

vars:
	@echo "\033[36mCommon:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"

install: check_hosts ## Install reverseproxy's nginx and oauth2 containers
	@ansible-playbook $(PLAYBOOKS_DIR)/proxy.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_VAULT_EXTRA_ARGS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

destroy: check_hosts ## Destroy reverseproxy's nginx and oauth2 containers
	@echo "reverseproxy: destroy not implemented"

help: ## Show Help
	@echo "Reverseproxy targets - make playbooks reverseproxy <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

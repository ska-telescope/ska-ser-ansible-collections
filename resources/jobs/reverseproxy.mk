.PHONY: reverse-proxy-check-hosts vars install destroy help
.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
ANSIBLE_EXTRA_VARS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)
PLAYBOOKS_DIR ?= ./ansible_collections/ska_collections/reverseproxy/playbooks

-include $(BASE_PATH)/PrivateRules.mak

reverse-proxy-check-hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

reverse-proxy-vars:
	@echo "\033[36mCommon:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"

reverse-proxy-install: reverse-proxy-check-hosts ## Install reverseproxy's nginx and oauth2 containers
	ansible-playbook $(PLAYBOOKS_DIR)/install.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

reverse-proxy-destroy: reverse-proxy-check-hosts ## Destroy reverseproxy's nginx and oauth2 containers
	ansible-playbook $(PLAYBOOKS_DIR)/destroy.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

reverse-proxy-help: ## Show Help
	@echo "Reverseproxy targets - make playbooks reverseproxy <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

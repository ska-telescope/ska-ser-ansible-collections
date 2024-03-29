.PHONY: check_hosts vars install destroy help
.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
ANSIBLE_EXTRA_VARS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)
PLAYBOOKS_DIR ?= ./ansible_collections/ska_collections/gateway/playbooks

## VPN args
OPENVPN_CLIENT ?=
OPENVPN_CLIENT_EMAIL ?=
KEYSERVER ?= keyserver.ubuntu.com

-include $(BASE_PATH)/PrivateRules.mak

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

check_inputs:
ifndef OPENVPN_CLIENT
	$(error OPENVPN_CLIENT is undefined)
endif
ifndef OPENVPN_CLIENT_EMAIL
	$(error OPENVPN_CLIENT_EMAIL is undefined)
endif

vars:
	@echo "\033[36mopenvpn:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"

install: check_hosts ## Install openvpn server
	ansible-playbook $(PLAYBOOKS_DIR)/openvpn_server.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

destroy: check_hosts ## Destroy openvpn server
	ansible-playbook $(PLAYBOOKS_DIR)/openvpn_server_destroy.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

add-client: check_hosts check_inputs ## Destroy openvpn server
	ansible-playbook $(PLAYBOOKS_DIR)/openvpn_add_client.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" --extra-vars "openvpn_client=$(OPENVPN_CLIENT)" \
	--extra-vars "openvpn_client_email=$(OPENVPN_CLIENT_EMAIL)"

delete-client: check_hosts check_inputs ## Destroy openvpn server
	ansible-playbook $(PLAYBOOKS_DIR)/openvpn_remove_client.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" --extra-vars "openvpn_client=$(OPENVPN_CLIENT)" \
	--extra-vars "openvpn_client_email=$(OPENVPN_CLIENT_EMAIL)"

backup: check_hosts ## Backup pki and generated credentials
	ansible-playbook $(PLAYBOOKS_DIR)/openvpn_backup.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

restore: check_hosts ## Restore pki and generated credentials
	ansible-playbook $(PLAYBOOKS_DIR)/openvpn_restore.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

help: ## Show Help
	@echo "openvpn targets - make playbooks openvpn <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

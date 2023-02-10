.PHONY: check_hosts vars install destroy help
.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
ANSIBLE_EXTRA_VARS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)
PLAYBOOKS_DIR ?= ./ansible_collections/ska_collections/gateway/playbooks

-include $(BASE_PATH)/PrivateRules.mak

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

vars:
	@echo "\033[36mGateway:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"

jumphost: check_hosts ## Add ubuntu users and configure jumphost
	ansible-playbook $(PLAYBOOKS_DIR)/jumphost_configure_user_access.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

cronjob: check_hosts ## Add ubuntu users and configure jumphost
	ansible-playbook $(PLAYBOOKS_DIR)/cron_add_configure_cronjob.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"
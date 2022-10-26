INVENTORY_FILE ?= $(PLAYBOOKS_ROOT_DIR)/inventory.yml 
PLAYBOOK_PATH ?= ./ansible_collections/ska_collections/instance_common/playbooks
BIFROST_VARS ?= ./environments/$(ENVIRONMENT)/installation/group_vars/bifrost.yml
BIFROST_CLUSTER_NAME ?= terminus
BIFROST_EXTRA_VARS ?= jump_host=' -F $(PLAYBOOKS_ROOT_DIR)/ssh.config $(BIFROST_CLUSTER_NAME) '
ANSIBLE_PLAYBOOK_ARGUMENTS ?=

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif


reverseproxy: check_hosts ## Install nginx reverse proxy
	ansible-playbook $(PLAYBOOK_PATH)/proxy.yml \
	-i $(INVENTORY_FILE) \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
	-e @../$(BIFROST_VARS) \
	--extra-vars " \
		target_hosts=$(PLAYBOOKS_HOSTS) \
		oauth2proxy_client_id=$(AZUREAD_CLIENT_ID) \
		oauth2proxy_client_secret=$(AZUREAD_CLIENT_SECRET) \
		oauth2proxy_cookie_secret=$(AZUREAD_COOKIE_SECRET) \
		oauth2proxy_tenant_id=$(AZUREAD_TENANT_ID) \
		ansible_python_interpreter='/usr/bin/python3' \
		$(BIFROST_EXTRA_VARS) \
	"

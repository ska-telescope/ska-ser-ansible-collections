INVENTORY_FILE ?= $(PLAYBOOKS_ROOT_DIR)/inventory.yml 
PLAYBOOK_PATH ?= ./ansible_collections/ska_collections/instance_common/playbooks
BIFROST_VARS ?= ./environments/$(ENVIRONMENT)/installation/group_vars/bifrost.yml
BIFROST_CLUSTER_NAME ?= jupiter
BIFROST_EXTRA_VARS ?= jump_host=' -F $(THIS_BASE)/ssh.config $(BIFROST_CLUSTER_NAME) '

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif


reverseproxy: ## Install nginx reverse proxy
	@ansible-playbook -i $(INVENTORY_FILE) $(PLAYBOOK_PATH)/proxy.yml \
		-e @../$(BIFROST_VARS) \
		--extra-vars="$(BIFROST_EXTRA_VARS)" \
		--extra-vars="oauth2proxy_client_id='$(AZUREAD_CLIENT_ID)'" \
		--extra-vars="oauth2proxy_client_secret='$(AZUREAD_CLIENT_SECRET)'" \
		--extra-vars="oauth2proxy_cookie_secret='$(AZUREAD_COOKIE_SECRET)'" \
		--extra-vars="oauth2proxy_tenant_id='$(AZUREAD_TENANT_ID)'" \
		-e "target_hosts='$(PLAYBOOKS_HOSTS)'" \
		-e 'ansible_python_interpreter=/usr/bin/python3'

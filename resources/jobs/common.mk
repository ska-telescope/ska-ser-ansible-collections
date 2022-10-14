INVENTORY_FILE ?= $(PLAYBOOKS_ROOT_DIR)/inventory.yml 
PLAYBOOK_PATH ?= ./ansible_collections/ska_collections/instance_common/playbooks
BIFROST_VARS ?= ../environments/$(ENVIRONMENT)/installation/group_vars/prometheus.yml
BIFROST_CLUSTER_NAME ?= jupiter
BIFROST_EXTRA_VARS ?= registry_mirror='$(REGISTRY_MIRROR)' \
docker_hub_mirror='$(REGISTRY_MIRROR)' \
podman_registry_mirror='$(PODMAN_REGISTRY_MIRROR)' \
jump_host=' -F $(THIS_BASE)/ssh.config $(BIFROST_CLUSTER_NAME) '

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif


reverseproxy: ## Install nginx reverse proxy
	cd playbooks && \
	ansible-playbook  -i $(INVENTORY_FILE) $(BIFROST_CLUSTER_NAME) $(PLAYBOOK_PATH)/proxy.yml \
		-e @../$(BIFROST_VARS) \
		--extra-vars="$(BIFROST_EXTRA_VARS)" \
		--extra-vars="oauth2proxy_client_id='$(AZUREAD_CLIENT_ID)'" \ 
		--extra-vars="oauth2proxy_client_secret='$(AZUREAD_CLIENT_SECRET)'" \
		--extra-vars="oauth2proxy_cookie_secret='$(AZUREAD_COOKIE_SECRET)'" \ 
		--extra-vars="oauth2proxy_tenant_id='$(AZUREAD_TENANT_ID)'"

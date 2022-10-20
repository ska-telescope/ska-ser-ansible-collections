## OPENSTACK VARIABLES
PROM_OS_PROJECT_ID ?=geral;system-team;admin
PROM_OS_AUTH_URL ?= http://192.168.93.215:5000/v3/

V ?=
PRIVATE_VARS ?= extra_vars.yml
INVENTORY_FILE ?= $(PLAYBOOKS_ROOT_DIR)/inventory.yml 
NODES ?= all
PROMETHEUS_NODE ?= prometheus
EXTRA_VARS ?= extra_vars.yml
COLLECTIONS_PATHS ?= ./collections

SLACK_API_URL ?= ******************
SLACK_API_URL_MVP ?= ******************
SLACK_CHANNEL ?= prometheus-alerts
SLACK_CHANNEL_MVP ?= proj-mvp-messages
PROMETHEUS_ALERTMANAGER_URL ?= http://monitoring.skao.stfc:9093
PROMETHEUS_URL ?= http://monitoring.skao.stfc:9090
PROM_CONFIGS_PATH ?= .

KUBECONFIG ?= "mandatory"
GITLAB_TOKEN ?= "mandatory"
CA_CERT_PASSWORD ?= "mandatory"

# AzureAD vars
AZUREAD_CLIENT_ID ?=
AZUREAD_CLIENT_SECRET ?=
AZUREAD_TENANT_ID ?=

.DEFAULT_GOAL := help
PROMETHEUS_EXTRAVARS ?=

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

vars:  ## Variables
	@echo "Current variable settings:"
	@echo "PRIVATE_VARS=$(PRIVATE_VARS)"
	@echo "CLUSTER_KEYPAIR=$(CLUSTER_KEYPAIR)"
	@echo "INVENTORY_FILE=$(INVENTORY_FILE)"
	@echo "EXTRA_VARS=$(EXTRA_VARS)"
	@echo "ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS)"
	@echo "STACK_CLUSTER_PLAYBOOKS=$(STACK_CLUSTER_PLAYBOOKS)"
	@echo "DOCKER_PLAYBOOKS=$(DOCKER_PLAYBOOKS)"

lint: ## Lint playbooks
	yamllint -d "{extends: relaxed, rules: {line-length: {max: 350}}}" \
			./ansible_collections/ska_collections/monitoring/playbooks/deploy_docker_exporter.yml  \
			./ansible_collections/ska_collections/monitoring/playbooks/deploy_node_exporter.yml  \
			./ansible_collections/ska_collections/monitoring/playbooks/deploy_monitoring.yml \
			./ansible_collections/ska_collections/monitoring/playbooks/export_runners.yml  \
			./ansible_collections/ska_collections/monitoring/roles/*
	ansible-lint --exclude=roles/prometheus/files \
	 ./ansible_collections/ska_collections/monitoring/playbooks/deploy_docker_exporter.yml \
	 ./ansible_collections/ska_collections/monitoring/playbooks/deploy_node_exporter.yml \
	 ./ansible_collections/ska_collections/monitoring/playbooks/deploy_monitoring.yml  \
	 ./ansible_collections/ska_collections/monitoring/playbooks/export_runners.yml \
	  ./ansible_collections/ska_collections/monitoring/roles/*  > ansible-lint-results.txt; \
	cat ansible-lint-results.txt
	flake8 --exclude ./ansible_collections/ska_collections/monitoring/roles/prometheus/files/openstack roles/*

prometheus: check_hosts ## Install Prometheus Server
	ansible-playbook ./ansible_collections/ska_collections/monitoring/playbooks/deploy_monitoring.yml \
		-i $(PLAYBOOKS_ROOT_DIR)/$(INVENTORY_FILE) \
		-e "mode='server' slack_api_url='$(SLACK_API_URL)' slack_api_url_mvp='$(SLACK_API_URL_MVP)'" \
		--extra-vars="registry_mirror='$(REGISTRY_MIRROR)' docker_hub_mirror='$(REGISTRY_MIRROR)' podman_registry_mirror='$(PODMAN_REGISTRY_MIRROR)'" \
		--extra-vars="azuread_client_id='$(AZUREAD_CLIENT_ID)' azuread_client_secret='$(AZUREAD_CLIENT_SECRET)' azuread_tenant_id='$(AZUREAD_TENANT_ID)'" \
		-e "slack_channel='$(SLACK_CHANNEL)'" \
		-e "slack_channel_mvp='$(SLACK_CHANNEL_MVP)'" \
		-e "prometheus_alertmanager_url='$(PROMETHEUS_ALERTMANAGER_URL)'" \
		-e "project_name='$(PROM_OS_PROJECT_NAME)' project_id='$(PROM_OS_PROJECT_ID)' auth_url='$(PROM_OS_AUTH_URL)'" kubeconfig='$(KUBECONFIG)'" \
		-e "username='$(PROM_OS_USERNAME)' password='$(PROM_OS_PASSWORD)'" \
		-e "prometheus_url='$(PROMETHEUS_URL)'" $(PROMETHEUS_EXTRAVARS) \
		-e "prometheus_gitlab_ci_pipelines_exporter_token=$(GITLAB_TOKEN)" \
		-e "ca_cert_pass=$(CA_CERT_PASSWORD)" \
		-e @$(PROM_CONFIGS_PATH)/ansible_collections/ska_collections/monitoring/group_vars/all.yml \
		-e @$(PROM_CONFIGS_PATH)/prometheus_node_metric_relabel_configs.yaml \
		-e @$(PROM_CONFIGS_PATH)/../environments/$(ENVIRONMENT)/installation/group_vars/prometheus.yml \
		-e "target_hosts='$(PLAYBOOKS_HOSTS)'" \
		-e 'ansible_python_interpreter=/usr/bin/python3' $(V)

thanos: check_hosts ## Install Thanos query and query front-end
	ansible-playbook ./ansible_collections/ska_collections/monitoring/playbooks/deploy_monitoring.yml \
		--extra-vars "mode='thanos'" \
		-e "ca_cert_pass=$(CA_CERT_PASSWORD)" \
		-e "project_name='$(PROM_OS_PROJECT_NAME)' project_id='$(PROM_OS_PROJECT_ID)' auth_url='$(PROM_OS_AUTH_URL)'" \
		-e "username='$(PROM_OS_USERNAME)' password='$(PROM_OS_PASSWORD)'" \
		-i $(PLAYBOOKS_ROOT_DIR)/$(INVENTORY_FILE) \
		-e @$(PROM_CONFIGS_PATH)/ansible_collections/ska_collections/monitoring/group_vars/all.yml \
		-e @$(PROM_CONFIGS_PATH)/../environments/$(ENVIRONMENT)/installation/group_vars/prometheus.yml \
		-e "target_hosts='$(PLAYBOOKS_HOSTS)'" \
		-e 'ansible_python_interpreter=/usr/bin/python3' $(V)

node-exporter: check_hosts ## Install Prometheus node exporter - pass INVENTORY_FILE and NODES
	ansible-playbook deploy_node_exporter.yml -i $(PLAYBOOKS_ROOT_DIR)/$(INVENTORY_FILE) \
	-e 'ansible_python_interpreter=/usr/bin/python3' \
	-e @$(EXTRA_VARS) \
	--limit $(NODES)

update_metadata: check_hosts ## OpenStack metadata for node_exporters - pass INVENTORY_FILE all format should be OK
	ansible -i $(PLAYBOOKS_ROOT_DIR)/$(INVENTORY_FILE) $(PROMETHEUS_NODE) -b -m copy -a 'src=$(INVENTORY_FILE) dest=/tmp/all_inventory'
	@ansible -i $(PLAYBOOKS_ROOT_DIR)/$(INVENTORY_FILE) $(PROMETHEUS_NODE) -b -m shell -a 'export project_name=$(PROM_OS_PROJECT_NAME) project_id=$(PROM_OS_PROJECT_ID) auth_url=$(PROM_OS_AUTH_URL) username=$(PROM_OS_USERNAME) password=$(PROM_OS_PASSWORD)	os_region_name=RegionOne os_interface=public PROM_OS_PROJECT_ID=$(PROM_OS_PROJECT_ID)	os_user_domain_name=default	os_identity_api_version=3 && python3 /usr/local/bin/prom_helper.py -u /tmp/all_inventory'

update_scrapers: check_hosts ## Force update of scrapers
	ansible -i $(PLAYBOOKS_ROOT_DIR)/$(INVENTORY_FILE) $(PROMETHEUS_NODE) -b -m shell -a 'export project_id=$(PROM_OS_PROJECT_ID) project_name=$(PROM_OS_PROJECT_NAME) auth_url=$(PROM_OS_AUTH_URL) username=$(PROM_OS_USERNAME) password=$(PROM_OS_PASSWORD) $(OPENSTACK_ENV_VARIABLES) && cd /etc/prometheus && python3 /usr/local/bin/prom_helper.py -g'

help: ## Show Help
	@echo "Monitoring solution targets - make playbooks monitoring <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

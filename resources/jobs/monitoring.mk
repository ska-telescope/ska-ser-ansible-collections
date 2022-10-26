.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)

## EXECUTION VARIABLES
NODES ?= all
PRIVATE_VARS ?= extra_vars.yml
EXTRA_VARS ?= extra_vars.yml
PROMETHEUS_NODE ?= prometheus
COLLECTIONS_PATHS ?= ./collections

## OPENSTACK VARIABLES
PROM_OS_PROJECT_ID ?=geral;system-team;admin
PROM_OS_AUTH_URL ?= http://192.168.93.215:5000/v3/

SLACK_API_URL ?= ******************
SLACK_API_URL_USER ?= ******************
PROM_CONFIGS_PATH ?= .

KUBECONFIG ?= "mandatory"
GITLAB_TOKEN ?= "mandatory"
CA_CERT_PASSWORD ?= "mandatory"

# AzureAD vars
AZUREAD_CLIENT_ID ?=
AZUREAD_CLIENT_SECRET ?=
AZUREAD_TENANT_ID ?=

PROMETHEUS_EXTRAVARS ?=

-include $(BASE_PATH)/PrivateRules.mak

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

vars:  ## Variables
	@echo "\033[36mMonitoring:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"
	@echo "SLACK_API_URL=$(SLACK_API_URL)"
	@echo "SLACK_API_URL_USER=$(SLACK_API_URL_USER)"
	@echo "AZUREAD_CLIENT_ID=$(AZUREAD_CLIENT_ID)"
	@echo "AZUREAD_CLIENT_SECRET=$(AZUREAD_CLIENT_SECRET)"
	@echo "CA_CERT_PASSWORD=$(CA_CERT_PASSWORD)"
	@echo "PROM_OS_PROJECT_ID=$(PROM_OS_PROJECT_ID)"
	@echo "PROM_OS_AUTH_URL=$(PROM_OS_AUTH_URL)"
	@echo "PROM_OS_USERNAME=$(PROM_OS_USERNAME)"
	@echo "PROM_OS_PASSWORD=$(PROM_OS_PASSWORD)"
	@echo "PROMETHEUS_NODE=$(PROMETHEUS_NODE)"
	@echo "GITLAB_TOKEN=$(GITLAB_TOKEN)"
	@echo "KUBECONFIG=$(KUBECONFIG)"
	@echo "NODES=$(NODES)"

lint: ## Lint playbooks
	@yamllint -d "{extends: relaxed, rules: {line-length: {max: 350}}}" \
			./ansible_collections/ska_collections/monitoring/playbooks/deploy_docker_exporter.yml  \
			./ansible_collections/ska_collections/monitoring/playbooks/deploy_node_exporter.yml  \
			./ansible_collections/ska_collections/monitoring/playbooks/deploy_monitoring.yml \
			./ansible_collections/ska_collections/monitoring/playbooks/export_runners.yml  \
			./ansible_collections/ska_collections/monitoring/roles/*
	@ansible-lint --exclude=./ansible_collections/ska_collections/monitoring/roles/prometheus/files/ \
	 ./ansible_collections/ska_collections/monitoring/playbooks/deploy_docker_exporter.yml \
	 ./ansible_collections/ska_collections/monitoring/playbooks/deploy_node_exporter.yml \
	 ./ansible_collections/ska_collections/monitoring/playbooks/deploy_monitoring.yml  \
	 ./ansible_collections/ska_collections/monitoring/playbooks/export_runners.yml \
	  ./ansible_collections/ska_collections/monitoring/roles/*  > ansible-lint-results.txt; \
	cat ansible-lint-results.txt
	@flake8 --exclude ./ansible_collections/ska_collections/monitoring/roles/prometheus/files/openstack roles/*

prometheus: check_hosts ## Install Prometheus Server
	ansible-playbook ./ansible_collections/ska_collections/monitoring/playbooks/deploy_monitoring.yml \
		-i $(INVENTORY) \
		$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
		-e "mode='server' slack_api_url='$(SLACK_API_URL)' slack_api_url_user='$(SLACK_API_URL_USER)'" \
		--extra-vars="azuread_client_id='$(AZUREAD_CLIENT_ID)' azuread_client_secret='$(AZUREAD_CLIENT_SECRET)' azuread_tenant_id='$(AZUREAD_TENANT_ID)'" \
		-e "project_id='$(PROM_OS_PROJECT_ID)' auth_url='$(PROM_OS_AUTH_URL)' kubeconfig='$(KUBECONFIG)'" \
		-e "username='$(PROM_OS_USERNAME)' password='$(PROM_OS_PASSWORD)'" $(PROMETHEUS_EXTRAVARS) \
		-e "prometheus_gitlab_ci_pipelines_exporter_token=$(GITLAB_TOKEN)" \
		-e "ca_cert_pass=$(CA_CERT_PASSWORD)" \
		-e @$(PROM_CONFIGS_PATH)/ansible_collections/ska_collections/monitoring/group_vars/all.yml \
		-e @$(PROM_CONFIGS_PATH)/prometheus_node_metric_relabel_configs.yaml \
		-e @$(PROM_CONFIGS_PATH)/../environments/$(ENVIRONMENT)/installation/group_vars/prometheus.yml \
		-e "target_hosts='$(PLAYBOOKS_HOSTS)'" \
		-e 'ansible_python_interpreter=/usr/bin/python3'

grafana: check_hosts ## Install Grafana Server
	@ansible-playbook ./ansible_collections/ska_collections/monitoring/playbooks/deploy_monitoring.yml \
		-i $(INVENTORY) \
		$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
		-e "mode='grafana'" \
		--extra-vars="azuread_client_id='$(AZUREAD_CLIENT_ID)' azuread_client_secret='$(AZUREAD_CLIENT_SECRET)' azuread_tenant_id='$(AZUREAD_TENANT_ID)'" \
		-e @$(PROM_CONFIGS_PATH)/ansible_collections/ska_collections/monitoring/group_vars/all.yml \
		-e @$(PROM_CONFIGS_PATH)/prometheus_node_metric_relabel_configs.yaml \
		-e @$(PROM_CONFIGS_PATH)/../environments/$(ENVIRONMENT)/installation/group_vars/prometheus.yml \
		-e "target_hosts='$(PLAYBOOKS_HOSTS)'" \
		-e 'ansible_python_interpreter=/usr/bin/python3'

alertmanager: check_hosts ## Install Prometheus Server
	ansible-playbook ./ansible_collections/ska_collections/monitoring/playbooks/deploy_monitoring.yml \
		-i $(INVENTORY) \
		$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
		-e "mode='alert' slack_api_url='$(SLACK_API_URL)' slack_api_url_user='$(SLACK_API_URL_USER)'" \
		-e @$(PROM_CONFIGS_PATH)/ansible_collections/ska_collections/monitoring/group_vars/all.yml \
		-e @$(PROM_CONFIGS_PATH)/prometheus_node_metric_relabel_configs.yaml \
		-e @$(PROM_CONFIGS_PATH)/../environments/$(ENVIRONMENT)/installation/group_vars/prometheus.yml \
		-e "target_hosts='$(PLAYBOOKS_HOSTS)'" \
		-e 'ansible_python_interpreter=/usr/bin/python3'

thanos: check_hosts ## Install Thanos query and query front-end
	@ansible-playbook ./ansible_collections/ska_collections/monitoring/playbooks/deploy_monitoring.yml \
		-i $(INVENTORY) \
		$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
		--extra-vars "mode='thanos'" \
		-e "ca_cert_pass=$(CA_CERT_PASSWORD)" \
		-e "project_id='$(PROM_OS_PROJECT_ID)' auth_url='$(PROM_OS_AUTH_URL)'" \
		-e "username='$(PROM_OS_USERNAME)' password='$(PROM_OS_PASSWORD)'" \
		-e @$(PROM_CONFIGS_PATH)/ansible_collections/ska_collections/monitoring/group_vars/all.yml \
		-e @$(PROM_CONFIGS_PATH)/../environments/$(ENVIRONMENT)/installation/group_vars/prometheus.yml \
		-e "target_hosts='$(PLAYBOOKS_HOSTS)'" \
		-e 'ansible_python_interpreter=/usr/bin/python3'

node-exporter: check_hosts ## Install Prometheus node exporter - pass INVENTORY and NODES
	@ansible-playbook deploy_node_exporter.yml \
	-i $(INVENTORY) \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
	-e 'ansible_python_interpreter=/usr/bin/python3' \
	-e @$(EXTRA_VARS) \
	--limit $(NODES)

update_metadata: check_hosts ## OpenStack metadata for node_exporters - pass INVENTORY all format should be OK
	@ansible -i $(INVENTORY) $(PROMETHEUS_NODE) $(ANSIBLE_PLAYBOOK_ARGUMENTS) -b -m copy -a 'src=$(INVENTORY) dest=/tmp/all_inventory'
	@ansible -i $(INVENTORY) $(PROMETHEUS_NODE) $(ANSIBLE_PLAYBOOK_ARGUMENTS) -b -m shell -a 'export project_name=$(PROM_OS_PROJECT_NAME) project_id=$(PROM_OS_PROJECT_ID) auth_url=$(PROM_OS_AUTH_URL) username=$(PROM_OS_USERNAME) password=$(PROM_OS_PASSWORD)	os_region_name=RegionOne os_interface=public PROM_OS_PROJECT_ID=$(PROM_OS_PROJECT_ID)	os_user_domain_name=default	os_identity_api_version=3 && python3 /usr/local/bin/prom_helper.py -u /tmp/all_inventory'

update_scrapers: check_hosts ## Force update of scrapers
	@ansible -i $(INVENTORY) $(PROMETHEUS_NODE) $(ANSIBLE_PLAYBOOK_ARGUMENTS) -b -m shell -a 'export project_id=$(PROM_OS_PROJECT_ID) project_name=$(PROM_OS_PROJECT_NAME) auth_url=$(PROM_OS_AUTH_URL) username=$(PROM_OS_USERNAME) password=$(PROM_OS_PASSWORD) $(OPENSTACK_ENV_VARIABLES) && cd /etc/prometheus && python3 /usr/local/bin/prom_helper.py -g'

help: ## Show Help
	@echo "Monitoring targets - make playbooks monitoring <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

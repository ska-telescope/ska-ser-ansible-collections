.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)
PLAYBOOKS_DIR ?= ./ansible_collections/ska_collections/monitoring/playbooks
TESTS_DIR ?= ./ansible_collections/ska_collections/monitoring/tests
ANSIBLE_EXTRA_VARS ?=

## EXECUTION VARIABLES
NODES ?= all
PROMETHEUS_NODE ?= prometheus
COLLECTIONS_PATHS ?= ./collections

THANOS_OS_PASSWORD ?= "" ## Openstak password, mandatory for swift configuration

SLACK_API_URL ?= "" ## Webhook URL for infrastructural alerts
SLACK_API_URL_USER ?= "" ## Webhook URL for user/developer alerts
PROM_CONFIGS_PATH ?= .

KUBECONFIG ?= "" ## mandatory field for configuring the monitoring of k8s
GITLAB_TOKEN ?= "" ## mandatory field for configuring gitlab runner exporter
CA_CERT_PASSWORD ?= "" ## mandatory field for https configuration with the CA server

# AzureAD vars
AZUREAD_CLIENT_ID ?= "" ## mandatory field for configuring the authentication of grafana
AZUREAD_CLIENT_SECRET ?= "" ## mandatory field for configuring the authentication of grafana
AZUREAD_TENANT_ID ?= "" ## mandatory field for configuring the authentication of grafana

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
	@echo "AZUREAD_TENANT_ID=$(AZUREAD_TENANT_ID)"
	@echo "PROMETHEUS_NODE=$(PROMETHEUS_NODE)"
	@echo "GITLAB_TOKEN=$(GITLAB_TOKEN)"
	@echo "KUBECONFIG=$(KUBECONFIG)"
	@echo "NODES=$(NODES)"

lint: ## Lint playbooks
	@yamllint -d "{extends: relaxed, rules: {line-length: {max: 350}}}" \
			$(PLAYBOOKS_DIR)/deploy_docker_exporter.yml  \
			$(PLAYBOOKS_DIR)/deploy_node_exporter.yml  \
			$(PLAYBOOKS_DIR)/deploy_monitoring.yml \
			$(PLAYBOOKS_DIR)/export_runners.yml  \
			./ansible_collections/ska_collections/monitoring/roles/*
	@ansible-lint --exclude=./ansible_collections/ska_collections/monitoring/roles/prometheus/files/ \
	 $(PLAYBOOKS_DIR)/deploy_docker_exporter.yml \
	 $(PLAYBOOKS_DIR)/deploy_node_exporter.yml \
	 $(PLAYBOOKS_DIR)/deploy_monitoring.yml  \
	 $(PLAYBOOKS_DIR)/export_runners.yml \
	  ./ansible_collections/ska_collections/monitoring/roles/*  > ansible-lint-results.txt; \
	cat ansible-lint-results.txt
	@flake8 --exclude ./ansible_collections/ska_collections/monitoring/roles/prometheus/files/openstack roles/*

prometheus: check_hosts ## Install Prometheus Server
	@ansible-playbook $(PLAYBOOKS_DIR)/deploy_prometheus.yml \
		-i $(INVENTORY) \
		$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
		-e "kubeconfig='$(KUBECONFIG)'" \
		-e "ca_cert_password=$(CA_CERT_PASSWORD)" \
		-e "thanos_swift_server_password='$(THANOS_OS_PASSWORD)'" $(PROMETHEUS_EXTRAVARS) \
		-e "prometheus_gitlab_ci_pipelines_exporter_token=$(GITLAB_TOKEN)" \
		-e @$(PROM_CONFIGS_PATH)/prometheus_node_metric_relabel_configs.yaml \
		-e "target_hosts='$(PLAYBOOKS_HOSTS)'" \
		-e 'ansible_python_interpreter=/usr/bin/python3'

grafana: check_hosts ## Install Grafana Server
	@ansible-playbook $(PLAYBOOKS_DIR)/deploy_grafana.yml \
		-i $(INVENTORY) $(ANSIBLE_EXTRA_VARS) \
		$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
		--extra-vars="grafana_azuread_client_id='$(AZUREAD_CLIENT_ID)' grafana_azuread_client_secret='$(AZUREAD_CLIENT_SECRET)' grafana_azuread_tenant_id='$(AZUREAD_TENANT_ID)'" \
		-e @$(PROM_CONFIGS_PATH)/prometheus_node_metric_relabel_configs.yaml \
		-e "target_hosts='$(PLAYBOOKS_HOSTS)'" \
		-e 'ansible_python_interpreter=/usr/bin/python3'

alertmanager: check_hosts ## Install Prometheus Server
	@ansible-playbook $(PLAYBOOKS_DIR)/deploy_alertmanager.yml \
		-i $(INVENTORY) \
		$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
		-e "slack_api_url='$(SLACK_API_URL)' slack_api_url_user='$(SLACK_API_URL_USER)'" \
		-e "target_hosts='$(PLAYBOOKS_HOSTS)'" \
		-e 'ansible_python_interpreter=/usr/bin/python3'

thanos: check_hosts ## Install Thanos query and query front-end
	@ansible-playbook $(PLAYBOOKS_DIR)/deploy_thanos.yml \
		-i $(INVENTORY) \
		$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
		-e "ca_cert_password=$(CA_CERT_PASSWORD)" \
		-e "thanos_swift_server_password='$(PROM_OS_PASSWORD)'" \
		-e "target_hosts='$(PLAYBOOKS_HOSTS)'" \
		-e 'ansible_python_interpreter=/usr/bin/python3'

node-exporter: check_hosts ## Install Prometheus node exporter - pass INVENTORY and NODES
	@ansible-playbook $(PLAYBOOKS_DIR)/deploy_node_exporter.yml \
	-i $(INVENTORY) \
	-e "target_hosts='$(PLAYBOOKS_HOSTS)'" \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
	-e 'ansible_python_interpreter=/usr/bin/python3' \
	--limit $(NODES)

update_targets: check_hosts ## Update json file for prometheus targets definition
	@python3 ./ansible_collections/ska_collections/monitoring/roles/prometheus/files/helper/prom_helper.py -g "$(BASE_PATH)/datacentres/$(DATACENTRE)/*/installation"; \
	mv *.json ./ansible_collections/ska_collections/monitoring/roles/prometheus/files/ 2>/dev/null || true

test-prometheus: check_hosts ## Test elastic cluster
	@ansible-playbook $(TESTS_DIR)/prometheus_test.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

test-thanos: check_hosts ## Test elastic cluster
	@ansible-playbook $(TESTS_DIR)/thanos_test.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

help: ## Show Help
	@echo "Monitoring targets - make playbooks monitoring <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

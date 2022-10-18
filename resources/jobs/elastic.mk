.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
INVENTORY_FILE ?= $(PLAYBOOKS_ROOT_DIR)/inventory.yml

-include $(PLAYBOOKS_ROOT_DIR)/PrivateRules.mak

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

check_secrets:
ifndef CA_CERT_PASS
	$(error CA_CERT_PASS is undefined)
endif
ifndef ELASTICSEARCH_PASSWORD
	$(error ELASTICSEARCH_PASSWORD is undefined)
endif
ifndef ELASTIC_HAPROXY_STATS_PASSWORD
	$(error ELASTIC_HAPROXY_STATS_PASSWORD is undefined)
endif

vars:
	@echo "\033[36mElasticsearch:\033[0m"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"
	@echo "CA_CERT_PASS=$(CA_CERT_PASS)"
	@echo "ELASTICSEARCH_PASSWORD=$(ELASTICSEARCH_PASSWORD)"
	@echo "ELASTIC_HAPROXY_STATS_PASSWORD=$(ELASTIC_HAPROXY_STATS_PASSWORD)"

install: check_hosts check_secrets ## Install elastic
	ansible-playbook ./ansible_collections/ska_collections/elastic/playbooks/install.yml \
	-i $(INVENTORY_FILE) \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
	--extra-vars " \
		target_hosts=$(PLAYBOOKS_HOSTS) \
		ca_cert_pass=$(CA_CERT_PASS) \
		elasticsearch_password=$(ELASTICSEARCH_PASSWORD) \
		elastic_haproxy_stats_passwd=$(ELASTIC_HAPROXY_STATS_PASSWORD) \
		kibana_viewer_password=$(KIBANA_VIEWER_PASSWORD) \
	"

destroy: check_hosts ## Destroy elastic cluster
	ansible-playbook ./ansible_collections/ska_collections/elastic/playbooks/destroy.yml \
	-i $(INVENTORY_FILE) \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

help: ## Show Help
	@echo "Elastic targets - make playbooks elastic <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

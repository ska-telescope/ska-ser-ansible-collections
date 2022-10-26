.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)

-include $(BASE_PATH)/PrivateRules.mak

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

check_elastic_secrets:
ifndef CA_CERT_PASSWORD
	$(error CA_CERT_PASSWORD is undefined)
endif
ifndef ELASTICSEARCH_PASSWORD
	$(error ELASTICSEARCH_PASSWORD is undefined)
endif
ifndef ELASTIC_HAPROXY_STATS_PASSWORD
	$(error ELASTIC_HAPROXY_STATS_PASSWORD is undefined)
endif
ifndef KIBANA_VIEWER_PASSWORD
	$(error KIBANA_VIEWER_PASSWORD is undefined)
endif

vars:
	@echo "\033[36mElasticsearch:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"
	@echo "CA_CERT_PASSWORD=$(CA_CERT_PASSWORD)"
	@echo "ELASTICSEARCH_PASSWORD=$(ELASTICSEARCH_PASSWORD)"
	@echo "ELASTIC_HAPROXY_STATS_PASSWORD=$(ELASTIC_HAPROXY_STATS_PASSWORD)"
	@echo "KIBANA_VIEWER_PASSWORD=$(KIBANA_VIEWER_PASSWORD)"

install: check_hosts check_elastic_secrets ## Install elastic
	ansible-playbook ./ansible_collections/ska_collections/elastic/playbooks/install.yml \
	-i $(INVENTORY) \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
	--extra-vars " \
		target_hosts=$(PLAYBOOKS_HOSTS) \
		ca_cert_password=$(CA_CERT_PASSWORD) \
		elasticsearch_password=$(ELASTICSEARCH_PASSWORD) \
		elastic_haproxy_stats_passwd=$(ELASTIC_HAPROXY_STATS_PASSWORD) \
		kibana_viewer_password=$(KIBANA_VIEWER_PASSWORD) \
	"

destroy: check_hosts ## Destroy elastic cluster
	ansible-playbook ./ansible_collections/ska_collections/elastic/playbooks/destroy.yml \
	-i $(INVENTORY) \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

help: ## Show Help
	@echo "Elastic targets - make playbooks elastic <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

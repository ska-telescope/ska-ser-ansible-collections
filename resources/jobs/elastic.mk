.DEFAULT_GOAL := help

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

check_passwords:
ifndef CA_CERT_PASS
	$(error CA_CERT_PASS is undefined)
endif
ifndef ELASTIC_PASSWORD
	$(error ELASTIC_PASSWORD is undefined)
endif
ifndef ELASTIC_HAPROXY_STATS_PASS
	$(error ELASTIC_HAPROXY_STATS_PASS is undefined)
endif

vars:
	@echo "\033[36mElasticsearch:\033[0m"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"
	@echo "CA_CERT_PASS=$(CA_CERT_PASS)"
	@echo "ELASTIC_PASSWORD=$(ELASTIC_PASSWORD)"
	@echo "ELASTIC_HAPROXY_STATS_PASS=$(ELASTIC_HAPROXY_STATS_PASS)"

install: check_hosts check_passwords ## Install elastic
	ansible-playbook ./ansible_collections/ska_collections/elastic/playbooks/install.yml \
	-i $(PLAYBOOKS_ROOT_DIR) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS) ca_cert_pass=$(CA_CERT_PASS) elastic_password=$(ELASTIC_PASSWORD) elastic_elastic_haproxy_stats_passwd=$(ELASTIC_HAPROXY_STATS_PASS)"
	
destroy: check_hosts ## Destroy elastic cluster
	ansible-playbook ./ansible_collections/ska_collections/elastic/playbooks/destroy.yml \
	-i $(PLAYBOOKS_ROOT_DIR)\
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

help: ## Show Help
	@echo "ElasticSearch targets - make playbooks elastic <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
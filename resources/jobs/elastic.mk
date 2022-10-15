<<<<<<< HEAD
.DEFAULT_GOAL := help

=======
>>>>>>> ST-1400: Refactored elastic playbooks
check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

check_ca_pass:
ifndef CA_CERT_PASS
	$(error CA_CERT_PASS is undefined)
endif

check_elastic_pass:
ifndef ELASTIC_PASSWORD
	$(error ELASTIC_PASSWORD is undefined)
endif

install: check_hosts check_ca_pass check_elastic_pass ## Install elastic
	ansible-playbook ./ansible_collections/ska_collections/elastic/playbooks/install.yml \
	-i $(PLAYBOOKS_ROOT_DIR)/inventory.yml \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS) ca_cert_pass=$(CA_CERT_PASS) elastic_password=$(ELASTIC_PASSWORD)"
	
destroy: check_hosts ## Destroy elastic cluster
	ansible-playbook ./ansible_collections/ska_collections/elastic/playbooks/destroy.yml \
	-i $(PLAYBOOKS_ROOT_DIR)/inventory.yml \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

help: ## Show Help
	@echo "ElasticSearch targets - make playbooks elastic <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)

-include $(BASE_PATH)/PrivateRules.mak

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

check_logging_secrets:
ifndef CA_CERT_PASSWORD
	$(error CA_CERT_PASSWORD is undefined)
endif
ifndef ELASTICSEARCH_PASSWORD
        $(error ELASTICSEARCH_PASSWORD is undefined)
endif

vars:
	@echo "\033[36mLogging:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"
	@echo "CA_CERT_PASSWORD=$(CA_CERT_PASSWORD)"

install: check_hosts check_logging_secrets ## Install logging
	ansible-playbook ./ansible_collections/ska_collections/elastic/playbooks/logging.yml \
	-i $(INVENTORY) \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
	--extra-vars " \
		target_hosts=$(PLAYBOOKS_HOSTS) \
		ca_cert_password=$(CA_CERT_PASSWORD) \
		elasticsearch_password=$(ELASTICSEARCH_PASSWORD) \
	"

help: ## Show Help
	@echo "Logging targets - make playbooks logging <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

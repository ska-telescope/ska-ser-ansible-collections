.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
INVENTORY_FILE ?= $(PLAYBOOKS_ROOT_DIR)/inventory.yml 

-include $(BASE_PATH)/PrivateRules.mak

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

check_logging_secrets:
ifndef CA_CERT_PASS
	$(error CA_CERT_PASS is undefined)
endif
ifndef ELASTIC_PASSWORD
        $(error ELASTIC_PASSWORD is undefined)
endif

vars:
	@echo "\033[36mLogging:\033[0m"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"
	@echo "CA_CERT_PASS=$(CA_CERT_PASS)"

install: check_hosts check_logging_secrets ## Install logging
	ansible-playbook ./ansible_collections/ska_collections/elastic/playbooks/logging.yml \
	-i $(INVENTORY_FILE) \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
	--extra-vars " \
		target_hosts=$(PLAYBOOKS_HOSTS) \
		ca_cert_pass=$(CA_CERT_PASS) \
	"

help: ## Show Help
	@echo "Logging targets - make playbooks logging <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

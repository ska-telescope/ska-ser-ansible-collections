
check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

install: check_hosts ## Install logging
	ansible-playbook ./ansible_collections/ska_collections/elastic/playbooks/logging.yml \
	-i $(PLAYBOOKS_ROOT_DIR)/inventory.yml \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"
	
destroy: check_hosts ## Destroy logging - only the containers
	ansible-playbook ./ansible_collections/ska_collections/elastic/playbooks/logging.yml \
	-i $(PLAYBOOKS_ROOT_DIR)/inventory.yml \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

help: ## Show Help
	@echo "Logging targets - make playbooks logging <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

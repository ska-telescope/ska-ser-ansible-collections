.DEFAULT_GOAL := help
MAKEFLAGS += --no-print-directory
.PHONY: elastic

PLAYBOOKS_HOSTS?=all
JOBS_DIR=resources/jobs

# define overides for above variables in here
-include PrivateRules.mak

check-env:
ifndef ENVIRONMENT
	$(error ENVIRONMENT is undefined)
endif

vars:  ## Variables
	@echo "Current variable settings:"
	@echo "ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS)"

ping:  check-env ## Ping Ansible targets
	ansible all -i $(PLAYBOOKS_ROOT_DIR)/inventory.yml -m ping -l $(PLAYBOOKS_HOSTS)

# If the first argument is "oci"...
ifeq (oci,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "oci"
  TARGET_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(TARGET_ARGS):;@:)
endif

oci: check-env ## ElasticSearch targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/oci.mk

# If the first argument is "elastic"...
ifeq (elastic,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "elastic"
  TARGET_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(TARGET_ARGS):;@:)
endif

elastic: check-env ## ElasticSearch targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/elastic.mk

# If the first argument is "monitoring"...
ifeq (monitoring,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "monitoring"
  TARGET_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(TARGET_ARGS):;@:)
endif

monitoring: check-env ## ElasticSearch targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/monitoring.mk

help: ## Show Help
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}';
	@echo ""
	@echo "--------- Playbook Jobs ------------"
	@echo ""
	@$(foreach file, $(wildcard $(JOBS_DIR)/*), make help -f $(file); echo "";)
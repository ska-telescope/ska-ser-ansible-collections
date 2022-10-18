.DEFAULT_GOAL := help
MAKEFLAGS += --no-print-directory
.PHONY: elastic

PLAYBOOKS_HOSTS?=all
JOBS_DIR=resources/jobs
ANSIBLE_COLLECTIONS_PATHS ?=
PLAYBOOKS_ROOT_DIR ?=
ANSIBLE_LINT_PARAMETERS = --exclude ansible_collections/ska_collections/monitoring/roles/prometheus/files
PLAYBOOKS_HOSTS ?=

# standard make targets and Ansible support
include .make/base.mk
include .make/ansible.mk


# define overides for above variables in here
-include PrivateRules.mak

check-env:
ifndef ENVIRONMENT
	$(error ENVIRONMENT is undefined)
endif

vars:  ## Variables
	@echo "Current variable settings:"
	@echo "ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS)"
	@echo "PLAYBOOKS_ROOT_DIR=$(PLAYBOOKS_ROOT_DIR)"
	@echo "ANSIBLE_LINT_PARAMETERS=$(ANSIBLE_LINT_PARAMETERS)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"
	@echo "CA_CERT_PASS=$(CA_CERT_PASS)"
	@echo "ELASTIC_PASSWORD=$(ELASTIC_PASSWORD)"
	@echo "ELASTIC_HAPROXY_STATS_PASS=$(ELASTIC_HAPROXY_STATS_PASS)"

ping:  check-env ## Ping Ansible targets
	ansible all -i $(PLAYBOOKS_ROOT_DIR)/inventory.yml -m ping -l $(PLAYBOOKS_HOSTS)

JOBLIST := $(shell find $(JOBS_DIR) -iname '*.mk' -exec basename {} .mk ';')

# If the first argument matches a Makefile in the JOBS_DIR...
ifneq ($(filter $(JOBLIST),$(firstword $(MAKECMDGOALS))),)
  # use the rest as arguments for the job
  TARGET_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(TARGET_ARGS):;@:)
endif

oci: check-env ## ElasticSearch targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/oci.mk

elastic: check-env ## ElasticSearch targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/elastic.mk

logging: check-env ## Filebeat targets
	$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/logging.mk

clusterapi: check-env
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/clusterapi.mk

monitoring: check-env ## ElasticSearch targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/monitoring.mk

help-from-submodule: ## Show Help
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}';
	@echo ""
	@echo "--------- Playbook Jobs ------------"
	@echo ""
	@$(foreach file, $(wildcard $(JOBS_DIR)/*), make help -f $(file); echo "";)

help: ## Show Help
	@make vars;
	@echo "";
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}';
	@echo ""
	@echo "--------- Playbook Jobs ------------"
	@echo ""
	@$(foreach file, $(wildcard $(JOBS_DIR)/*), make help -f $(file); echo "";)

.DEFAULT_GOAL := help
MAKEFLAGS += --no-print-directory
.PHONY: logging

PLAYBOOKS_HOSTS ?= all
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)
JOBS_DIR = resources/jobs
ANSIBLE_COLLECTIONS_PATHS ?=
PLAYBOOKS_ROOT_DIR ?=
INVENTORY_FILE ?= inventory.yml
ANSIBLE_LINT_PARAMETERS = --exclude ansible_collections/ska_collections/monitoring/roles/prometheus/files
PLAYBOOKS_HOSTS ?=
ANSIBLE_CONFIG ?=

-include .make/base.mk
-include .make/ansible.mk

-include $(BASE_PATH)/PrivateRules.mak

ac-check-env:
ifndef ENVIRONMENT
	$(error ENVIRONMENT is undefined)
endif

vars:  ## Variables
	@echo "ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS)"
	@echo "PLAYBOOKS_ROOT_DIR=$(PLAYBOOKS_ROOT_DIR)"
	@echo "ANSIBLE_LINT_PARAMETERS=$(ANSIBLE_LINT_PARAMETERS)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"
	@echo "ANSIBLE_CONFIG=$(ANSIBLE_CONFIG)"
	@echo "CA_CERT_PASSWORD=$(CA_CERT_PASSWORD)"
	@echo "ELASTICSEARCH_PASSWORD=$(ELASTICSEARCH_PASSWORD)"
	@echo "ELASTIC_HAPROXY_STATS_PASSWORD=$(ELASTIC_HAPROXY_STATS_PASSWORD)"

ac-vars-recursive:
	@make vars;
	@echo ""
	@echo -e "\033[33m--------- Installation Jobs ------------\033[0m"
	@echo ""
	@$(foreach file, $(wildcard $(JOBS_DIR)/*.mk), make vars -f $(file); echo "";)

ac-ping: ac-check-env ## Ping Ansible targets
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif
	@ansible all -i $(INVENTORY) -m ping -l $(PLAYBOOKS_HOSTS)

ac-install-collections:  ## Install dependent ansible collections
	ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS) \
	ansible-galaxy collection install \
	-r requirements.yml -p ./ansible_collections

JOBLIST := $(shell find $(JOBS_DIR) -iname '*.mk' -exec basename {} .mk ';')

# If the first argument matches a Makefile in the JOBS_DIR...
ifneq ($(filter $(JOBLIST),$(firstword $(MAKECMDGOALS))),)
  # use the rest as arguments for the job
  TARGET_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(TARGET_ARGS):;@:)
endif

common: ac-check-env ## common targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/common.mk

oci: ac-check-env ## oci targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/oci.mk

logging: ac-check-env ## logging targets
	$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/logging.mk

monitoring: ac-check-env ## monitoring targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/monitoring.mk

ceph: ac-check-env ## ceph targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/ceph.mk

gitlab-runner: ac-check-env ## gitlab-runner targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/gitlab-runner.mk

ac-print-targets: ## Show Help
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {p=index($$1,":")} {printf "\033[36m%-30s\033[0m %s\n", substr($$1,p+1), $$2}';
	@echo ""
	@echo "--------- Playbook Jobs ------------"
	@echo ""
	@$(foreach file, $(wildcard $(JOBS_DIR)/*), make help -f $(file); echo "";)

help: ## Show Help
	@echo ""
	@echo "Vars:"
	@make vars;
	@make ac-print-targets

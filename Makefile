.DEFAULT_GOAL := help
MAKEFLAGS += --no-print-directory
VAULT_VARIABLE?=vault
.PHONY: elastic

PLAYBOOKS_HOSTS ?= all
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)
JOBS_DIR = resources/jobs
ANSIBLE_COLLECTIONS_PATHS ?=
PLAYBOOKS_ROOT_DIR ?=
INVENTORY_FILE ?= inventory.yml
ANSIBLE_LINT_PARAMETERS = --exclude ansible_collections/ska_collections/monitoring/roles/prometheus/files
PLAYBOOKS_HOSTS ?=
ANSIBLE_CONFIG ?=

include .make/base.mk
include .make/ansible.mk

-include $(BASE_PATH)/PrivateRules.mak

check-env:
ifndef DATACENTRE
	$(error DATACENTRE is undefined)
endif
ifndef ENVIRONMENT
	$(error ENVIRONMENT is undefined)
endif

vars:  ## Variables
	@echo "INVENTORY=$(INVENTORY)"
	@echo "ANSIBLE_CONFIG=$(ANSIBLE_CONFIG)"
	@echo "ANSIBLE_SSH_ARGS=$(ANSIBLE_SSH_ARGS)"
	@echo "ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS)"
	@echo "ANSIBLE_LINT_PARAMETERS=$(ANSIBLE_LINT_PARAMETERS)"
	@echo "ANSIBLE_VAULT_EXTRA_ARGS=$(ANSIBLE_VAULT_EXTRA_ARGS)"
	@echo ""
	@echo -e "\033[33m--------- Global Secrets ------------\033[0m"
	@echo -e $$(ansible -o -m ansible.builtin.debug \
		-a msg="_s_{{ ($(VAULT_VARIABLE).shared | to_nice_yaml) | default("") }}_e_" \
		$(ANSIBLE_VAULT_EXTRA_ARGS) localhost 2>/dev/null | grep -v "FAILED" | \
		sed 's#.*_s_\(.*\)_e_.*#\1#');
	@echo -e "\033[33m------- Environment Secrets-----------\033[0m"
	@echo -e $$(ansible -o -m ansible.builtin.debug \
		-a msg="_s_{{ ($(VAULT_VARIABLE)['$(DATACENTRE)']['$(ENVIRONMENT)'] | to_nice_yaml) | default("") }}_e_" \
		$(ANSIBLE_VAULT_EXTRA_ARGS) localhost 2>/dev/null | grep -v "FAILED" | \
		sed 's#.*_s_\(.*\)_e_.*#\1#');
	@echo -e "\033[33m----------- Job Secrets --------------\033[0m"
	@JOBS_LIST="$$(find $(JOBS_DIR) -name '*.mk')"; for JOB in $$JOBS_LIST; do \
		make vars -f $$JOB; \
		JOB_NAME=$$(basename $$JOB | sed 's#.mk##'); echo ""; \
		echo -e $$(ansible -o -m ansible.builtin.debug \
		-a msg="_s_{{ ($(VAULT_VARIABLE).shared['$$JOB_NAME'] | to_nice_yaml) | default("")}}_e_" \
		$(ANSIBLE_VAULT_EXTRA_ARGS) localhost 2>/dev/null | grep -v "FAILED" | \
		sed 's#.*_s_\(.*\)_e_.*#\1#'); \
		echo -e $$(ansible -o -m ansible.builtin.debug \
		-a msg="_s_{{ ($(VAULT_VARIABLE)['$(DATACENTRE)']['$(ENVIRONMENT)']['$$JOB_NAME'] | to_nice_yaml) | default("") }}_e_" \
		$(ANSIBLE_VAULT_EXTRA_ARGS) localhost 2>/dev/null | grep -v "FAILED" | \
		sed 's#.*_s_\(.*\)_e_.*#\1#'); \
	done
	@

ping: check-env ## Ping Ansible targets
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif
	@ansible all -i $(INVENTORY) -m ping -l $(PLAYBOOKS_HOSTS)

install_collections:  ## Install dependent ansible collections
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

common: check-env ## common targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/common.mk

oci: check-env ## oci targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/oci.mk

elastic: check-env ## elastic targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/elastic.mk

logging: check-env ## logging targets
	$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/logging.mk

reverseproxy: check-env ## reverseproxy targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/reverseproxy.mk

monitoring: check-env ## monitoring targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/monitoring.mk

ceph: check-env ## ceph targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/ceph.mk

gitlab-runner: check-env ## gitlab_runner targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/gitlab_runner.mk

print_targets: ## Show Help
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {p=index($$1,":")} {printf "\033[36m%-30s\033[0m %s\n", substr($$1,p+1), $$2}';
	@echo ""
	@echo "--------- Playbook Jobs ------------"
	@echo ""
	@$(foreach file, $(wildcard $(JOBS_DIR)/*), make help -f $(file); echo "";)

help: ## Show Help
	@echo ""
	@echo "Vars:"
	@make vars;
	@make print_targets
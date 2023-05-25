.DEFAULT_GOAL := help
MAKEFLAGS += --no-print-directory
SECRETS_ROOT_VAR?=secrets
.PHONY: ac-check-env vars ac-vars-recursive ac-ping ac-get-info ac-install-dependencies common oci logging reverseproxy monitoring ceph gitlab-runner nexus ac-print-targets help

INVENTORY?=$(PLAYBOOKS_ROOT_DIR)
JOBS_DIR=resources/jobs
ANSIBLE_COLLECTIONS ?= ./ansible_collections/ska_collections/
ANSIBLE_COLLECTIONS_PATHS ?=
PLAYBOOKS_ROOT_DIR ?=
ANSIBLE_LINT_PARAMETERS=--exclude ./ansible_collections/ska_collections/monitoring/roles/prometheus/files \
	--exclude ./ansible_collections/ansible-thoteam.nexus3-oss \
	--exclude ./ansible_collections/stackhpc \
	--skip-list "yaml[line-length],galaxy[no-changelog]"
PLAYBOOKS_HOSTS ?=
DELEGATE_HOSTS ?=
ANSIBLE_CONFIG ?=
ANSIBLE_SSH_ARGS ?=
ANSIBLE_EXTRA_VARS ?=

-include .make/base.mk
-include .make/ansible.mk
-include .make/python.mk

PYTHON_LINT_TARGET=./ansible_collections/ska_collections/clusterapi/playbooks/filter_plugins \
					./ansible_collections/ska_collections/clusterapi/plugins
PYTHON_SWITCHES_FOR_BLACK=--exclude .yml --exclude .yaml

-include $(BASE_PATH)/PrivateRules.mak

ac-check-env:
ifndef DATACENTRE
	$(error DATACENTRE is undefined)
endif
ifndef ENVIRONMENT
	$(error ENVIRONMENT is undefined)
endif

ac-vars:  ## Variables
	@echo "INVENTORY=$(INVENTORY)"
	@echo "ANSIBLE_CONFIG=$(ANSIBLE_CONFIG)"
	@echo "ANSIBLE_SSH_ARGS=$(ANSIBLE_SSH_ARGS)"
	@echo "ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS)"
	@echo "ANSIBLE_LINT_PARAMETERS=$(ANSIBLE_LINT_PARAMETERS)"
	@echo "ANSIBLE_EXTRA_VARS=$(ANSIBLE_EXTRA_VARS)"
	@echo ""
	@echo -e "\033[33m--------- Secrets ------------\033[0m"
	@echo -e $$(ansible -o -m ansible.builtin.debug \
		-a msg="_s_{{ ($(SECRETS_ROOT_VAR) | to_nice_yaml) | default("") }}_e_" \
		$(ANSIBLE_EXTRA_VARS) localhost 2>/dev/null | grep -v "FAILED" | \
		sed 's#.*_s_\(.*\)_e_.*#\1#');
	@echo -e "\033[33m--------- Shared Secrets ------------\033[0m"
	@echo -e $$(ansible -o -m ansible.builtin.debug \
		-a msg="_s_{{ ($(SECRETS_ROOT_VAR).shared | to_nice_yaml) | default("") }}_e_" \
		$(ANSIBLE_EXTRA_VARS) localhost 2>/dev/null | grep -v "FAILED" | \
		sed 's#.*_s_\(.*\)_e_.*#\1#');
	@echo -e "\033[33m------- Environment Secrets-----------\033[0m"
	@echo -e $$(ansible -o -m ansible.builtin.debug \
		-a msg="_s_{{ ($(SECRETS_ROOT_VAR)['$(DATACENTRE)']['$(ENVIRONMENT)'] | to_nice_yaml) | default("") }}_e_" \
		$(ANSIBLE_EXTRA_VARS) localhost 2>/dev/null | grep -v "FAILED" | \
		sed 's#.*_s_\(.*\)_e_.*#\1#');
	@echo ""
	@echo -e "\033[33m------------- Job Vars ---------------\033[0m"
	@make ac-vars-recursive;

ac-vars-recursive:
	@JOBS_LIST="$$(find $(JOBS_DIR) -name '*.mk')"; for JOB in $$JOBS_LIST; do \
		make vars -f $$JOB; \
		JOB_NAME=$$(basename $$JOB | sed 's#.mk##'); echo ""; \
		echo -e $$(ansible -o -m ansible.builtin.debug \
		-a msg="_s_{{ ($(SECRETS_ROOT_VAR).shared['$$JOB_NAME'] | to_nice_yaml) | default("")}}_e_" \
		$(ANSIBLE_EXTRA_VARS) localhost 2>/dev/null | grep -v "FAILED" | \
		sed 's#.*_s_\(.*\)_e_.*#\1#'); \
		echo -e $$(ansible -o -m ansible.builtin.debug \
		-a msg="_s_{{ ($(SECRETS_ROOT_VAR)['$(DATACENTRE)']['$(ENVIRONMENT)']['$$JOB_NAME'] | to_nice_yaml) | default("") }}_e_" \
		$(ANSIBLE_EXTRA_VARS) localhost 2>/dev/null | grep -v "FAILED" | \
		sed 's#.*_s_\(.*\)_e_.*#\1#'); \
	done

ac-ping: ac-check-env ## Ping Ansible targets
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif
	@ansible $(PLAYBOOKS_HOSTS) -i $(INVENTORY) -m ping $(ANSIBLE_PLAYBOOK_ARGUMENTS)

ac-info: ac-check-env ## Get Ansible targets' info
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif
	@FACTS=$$(echo "ansible_distribution \
		ansible_distribution_version \
		ansible_hostname \
		ansible_fqdn \
		ansible_default_ipv4" | \
		sed 's/ /,/g'); \
	ansible $(PLAYBOOKS_HOSTS) -i $(INVENTORY) -m ansible.builtin.gather_facts -a "filter=$$FACTS" $(ANSIBLE_PLAYBOOK_ARGUMENTS)

ac-ssh: ac-check-env ## Open ssh shell on target
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif
	@SSH_EXTRA_ARGS=$$(ansible-inventory -i $(INVENTORY) --host $(PLAYBOOKS_HOSTS) 2>/dev/null | jq -r '.ansible_ssh_extra_args // ""' ); \
	ssh $(ANSIBLE_SSH_ARGS) $$SSH_EXTRA_ARGS $(PLAYBOOKS_HOSTS)

ac-command: ac-check-env ## Run command on target
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif
ifndef ANSIBLE_PLAYBOOK_ARGUMENTS
	$(error ANSIBLE_PLAYBOOK_ARGUMENTS is undefined)
endif
	ansible $(PLAYBOOKS_HOSTS) -i $(INVENTORY) -m ansible.builtin.shell $(ANSIBLE_PLAYBOOK_ARGUMENTS)

ac-install-dependencies:  ## Install dependent ansible collections and roles
	ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS) \
	ansible-galaxy collection install \
	-r requirements.yml --force -p ./ansible_collections
	ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS) \
	ansible-galaxy role install \
	-r requirements.yml --force -p ./ansible_collections

ac-clean-namespaces:
	resources/scripts/clean-namespaces.sh $(CI_CLEAN_PAYLOAD)

JOBLIST := $(shell find $(JOBS_DIR) -iname '*.mk' -exec basename {} .mk ';')

# If the first argument matches a Makefile in the JOBS_DIR...
ifneq ($(filter $(JOBLIST),$(firstword $(MAKECMDGOALS))),)
  # use the rest as arguments for the job
  TARGET_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(TARGET_ARGS):;@:)
endif

gitlab-management:
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/gitlab-management.mk

clusterapi: ac-check-env ## clusterapi targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/clusterapi.mk

common: ac-check-env ## common targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/common.mk


k8s: ac-check-env ## k8s targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/k8s.mk

oci: ac-check-env ## oci targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/oci.mk

logging: ac-check-env ## logging targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/logging.mk

reverseproxy: ac-check-env ## reverseproxy targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/reverseproxy.mk

monitoring: ac-check-env ## monitoring targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/monitoring.mk

ceph: ac-check-env ## ceph targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/ceph.mk

gitlab-runner: ac-check-env ## gitlab_runner targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/gitlab-runner.mk

nexus: ac-check-env ## nexus targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/nexus.mk

metallb: ac-check-env ## metallb targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/metallb.mk

dns: ac-check-env ## dns targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/dns.mk

openvpn: ac-check-env ## openvpn targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/openvpn.mk

gateway: ac-check-env ## gateway targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/gateway.mk

binderhub: ac-check-env ## binderhub targets
	@$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/binderhub.mk

ac-print-targets: ## Show Help
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {p=index($$1,":")} {printf "\033[36m%-30s\033[0m %s\n", substr($$1,p+1), $$2}';
	@echo ""
	@echo "--------- Playbook Jobs ------------"
	@echo ""
	@$(foreach file, $(wildcard $(JOBS_DIR)/*), make help -f $(file); echo "";)

ac-help: ## Show Help
	@make ac-print-targets

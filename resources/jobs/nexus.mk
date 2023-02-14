.PHONY: vars help install apply-patch
.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)
PLAYBOOKS_DIR ?= ./ansible_collections/ska_collections/nexus/playbooks
TESTS_DIR ?= ./ansible_collections/ska_collections/nexus/tests
NEXUS_OSS_INSTALL_DIR ?= ./ansible_collections/ansible-thoteam.nexus3-oss

# define overides for above variables in here
-include $(BASE_PATH)/PrivateRules.mak

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

vars:
	@echo "\033[36mNexus:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"

install: check_hosts apply-patch # apply-patch  ## Deploy Nexus
	ANSIBLE_FILTER_PLUGINS=$(NEXUS_OSS_INSTALL_DIR)/filter_plugins \
	ansible-playbook $(PLAYBOOKS_DIR)/deploy.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

apply-patch:  ## apply patch to upstream nexus3-oss
	@if [ ! -d "$(NEXUS_OSS_INSTALL_DIR)" ]; then \
		echo "You need to install dependent packages first. Please run 'make playbooks ac-install-dependencies'"; \
		exit 1; \
	fi
	@if [ -f $(NEXUS_OSS_INSTALL_DIR)/.patched ]; then \
		echo "Nexus OSS collection already patched"; \
	else \
		git apply --directory $(NEXUS_OSS_INSTALL_DIR) \
			./ansible_collections/ska_collections/nexus/resources/nexus3-oss.patch --verbose --unsafe-paths && \
		touch $(NEXUS_OSS_INSTALL_DIR)/.patched; \
		echo "Nexus OSS collection patched"; \
	fi

test-apt-proxy-cache:  ## Test apt proxy and caching behavior
	ansible-playbook $(TESTS_DIR)/apt-proxy-cache.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

test-oci-proxy-cache:  ## Test oci proxy and caching behavior
	ansible-playbook $(TESTS_DIR)/oci-proxy-cache.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

help: ## Show Help
	@echo "Nexus targets - make playbooks nexus <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

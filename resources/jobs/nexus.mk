.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)

VAULT_NEXUS_ADMIN_PASSWORD ?= 'whatwhat'
VAULT_NEXUS_USER_PASSWORD_GITLAB ?= 'whatwhat'
VAULT_NEXUS_USER_PASSWORD_PUBLISHER ?= 'whatwhat'
VAULT_NEXUS_EMAIL_SERVER_PASSWORD ?= 'whatwhat'
VAULT_NEXUS_USER_PASSWORD_QUARANTINER ?= 'whatwhat'
VAULT_NEXUS_LDAP_CONN_PASSWD ?= 'whatwhat'
NEXUS_WEBHOOK_URL ?= 'http://localhost:8080'
NEXUS_WEBHOOK_SECRET_KEY ?= 'whatwhat'
NEXUS_APT_BIONIC_INTERNAL_KEY ?= 'whatwhat'
NEXUS_APT_BIONIC_INTERNAL_KEY_PASSPHRASE ?= 'whatwhat'
NEXUS_APT_BIONIC_QUARENTINE_KEY ?= 'whatwhat'
NEXUS_APT_BIONIC_QUARENTINE_KEY_PASSPHRASE ?= 'whatwhat'

.PHONY: vars help install apply-patch update-and-patch make-patch

# define overides for above variables in here
-include $(BASE_PATH)/PrivateRules.mak

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

vars:  ## List Variables
	@echo "Current variable settings:"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "VAULT_NEXUS_ADMIN_PASSWORD=$(VAULT_NEXUS_ADMIN_PASSWORD)"
	@echo "VAULT_NEXUS_USER_PASSWORD_GITLAB=$(VAULT_NEXUS_USER_PASSWORD_GITLAB)"
	@echo "VAULT_NEXUS_USER_PASSWORD_PUBLISHER=$(VAULT_NEXUS_USER_PASSWORD_PUBLISHER)"
	@echo "VAULT_NEXUS_EMAIL_SERVER_PASSWORD=$(VAULT_NEXUS_EMAIL_SERVER_PASSWORD)"
	@echo "VAULT_NEXUS_USER_PASSWORD_QUARANTINER=$(VAULT_NEXUS_USER_PASSWORD_QUARANTINER)"
	@echo "VAULT_NEXUS_LDAP_CONN_PASSWD=$(VAULT_NEXUS_LDAP_CONN_PASSWD)"
	@echo "NEXUS_WEBHOOK_URL=$(NEXUS_WEBHOOK_URL)"
	@echo "NEXUS_WEBHOOK_SECRET_KEY=$(NEXUS_WEBHOOK_SECRET_KEY)"
	@echo "NEXUS_APT_BIONIC_INTERNAL_KEY=$(NEXUS_APT_BIONIC_INTERNAL_KEY)"
	@echo "NEXUS_APT_BIONIC_INTERNAL_KEY_PASSPHRASE=$(NEXUS_APT_BIONIC_INTERNAL_KEY_PASSPHRASE)"
	@echo "NEXUS_APT_BIONIC_QUARENTINE_KEY=$(NEXUS_APT_BIONIC_QUARENTINE_KEY)"
	@echo "NEXUS_APT_BIONIC_QUARENTINE_KEY_PASSPHRASE=$(NEXUS_APT_BIONIC_QUARENTINE_KEY_PASSPHRASE)"

install: check_hosts apply-patch # apply-patch  ## Deploy Nexus
	ANSIBLE_FILTER_PLUGINS=./ansible_collections/ansible-thoteam.nexus3-oss/filter_plugins \
	ansible-playbook ./ansible_collections/ska_collections/nexus/playbooks/deploy.yml \
	-i $(INVENTORY) \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
	--extra-vars " \
		vault_nexus_admin_password=$(VAULT_NEXUS_ADMIN_PASSWORD) \
		vault_nexus_user_password_gitlab=$(VAULT_NEXUS_USER_PASSWORD_GITLAB) \
		vault_nexus_user_password_publisher=$(VAULT_NEXUS_USER_PASSWORD_PUBLISHER) \
		vault_nexus_email_server_password=$(VAULT_NEXUS_EMAIL_SERVER_PASSWORD) \
		vault_nexus_user_password_quarantiner=$(VAULT_NEXUS_USER_PASSWORD_QUARANTINER) \
		vault_nexus_ldap_conn_passwd=$(VAULT_NEXUS_LDAP_CONN_PASSWD) \
		nexus_webhook_url=$(NEXUS_WEBHOOK_URL) \
		nexus_webhook_secret_key=$(NEXUS_WEBHOOK_SECRET_KEY) \
		nexus_apt_bionic_internal_key=$(NEXUS_APT_BIONIC_INTERNAL_KEY) \
		nexus_apt_bionic_internal_key_passphrase=$(NEXUS_APT_BIONIC_INTERNAL_KEY_PASSPHRASE) \
		nexus_apt_bionic_quarentine_key=$(NEXUS_APT_BIONIC_QUARENTINE_KEY) \
		nexus_apt_bionic_quarentine_key_passphrase=$(NEXUS_APT_BIONIC_QUARENTINE_KEY_PASSPHRASE) \
		target_hosts=$(PLAYBOOKS_HOSTS) \
	"

apply-patch:  ## apply patch to upstream nexus3-oss
	# patch the nexus install for the oss edition
	if [ -f ./ansible_collections/ansible-thoteam.nexus3-oss/.patched ]; then \
	echo "Already patched !"; \
	else \
	git apply --directory ./ansible_collections/ansible-thoteam.nexus3-oss \
		./ansible_collections/ska_collections/nexus/resources/nexus3-oss.patch --verbose --unsafe-paths && \
	touch ./ansible_collections/ansible-thoteam.nexus3-oss/.patched; \
	fi

help: ## Show Help
	@echo "Nexus targets - make playbooks nexus <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
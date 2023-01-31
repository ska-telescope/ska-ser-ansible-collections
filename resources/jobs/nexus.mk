.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)

NEXUS_DEFAULT_ADMIN_PASSWORD ?=
NEXUS_VAULT_ADMIN_PASSWORD ?= 'whatwhat'
NEXUS_VAULT_USER_PASSWORD_GITLAB ?= 'whatwhat'
NEXUS_VAULT_USER_PASSWORD_PUBLISHER ?= 'whatwhat'
NEXUS_VAULT_EMAIL_SERVER_PASSWORD ?= 'whatwhat'
NEXUS_VAULT_USER_PASSWORD_QUARANTINER ?= 'whatwhat'
NEXUS_VAULT_LDAP_CONN_PASSWD ?= 'whatwhat'
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
	@echo "NEXUS_DEFAULT_ADMIN_PASSWORD=$(NEXUS_DEFAULT_ADMIN_PASSWORD)"
	@echo "NEXUS_VAULT_ADMIN_PASSWORD=$(NEXUS_VAULT_ADMIN_PASSWORD)"
	@echo "NEXUS_VAULT_USER_PASSWORD_GITLAB=$(NEXUS_VAULT_USER_PASSWORD_GITLAB)"
	@echo "NEXUS_VAULT_USER_PASSWORD_PUBLISHER=$(NEXUS_VAULT_USER_PASSWORD_PUBLISHER)"
	@echo "NEXUS_VAULT_EMAIL_SERVER_PASSWORD=$(NEXUS_VAULT_EMAIL_SERVER_PASSWORD)"
	@echo "NEXUS_VAULT_USER_PASSWORD_QUARANTINER=$(NEXUS_VAULT_USER_PASSWORD_QUARANTINER)"
	@echo "NEXUS_VAULT_LDAP_CONN_PASSWD=$(NEXUS_VAULT_LDAP_CONN_PASSWD)"
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
		nexus_default_admin_password=$(NEXUS_DEFAULT_ADMIN_PASSWORD) \
		nexus_vault_admin_password=$(NEXUS_VAULT_ADMIN_PASSWORD) \
		nexus_vault_user_password_gitlab=$(NEXUS_VAULT_USER_PASSWORD_GITLAB) \
		nexus_vault_user_password_publisher=$(NEXUS_VAULT_USER_PASSWORD_PUBLISHER) \
		nexus_vault_email_server_password=$(NEXUS_VAULT_EMAIL_SERVER_PASSWORD) \
		nexus_vault_user_password_quarantiner=$(NEXUS_VAULT_USER_PASSWORD_QUARANTINER) \
		nexus_vault_ldap_conn_passwd=$(NEXUS_VAULT_LDAP_CONN_PASSWD) \
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

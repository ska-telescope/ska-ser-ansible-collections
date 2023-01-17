.PHONY: check_hosts vars install destroy help
.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
ANSIBLE_EXTRA_VARS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)
PLAYBOOKS_DIR ?= ./ansible_collections/ska_collections/openvpn/playbooks

## VPN args
OPENVPN_CLIENT ?=
OPENVPN_CLIENT_EMAIL ?=
KEYSERVER ?= keyserver.ubuntu.com


-include $(BASE_PATH)/PrivateRules.mak

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

vars:
	@echo "\033[36mopenvpn:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"

install: check_hosts ## Install openvpn server
	ansible-playbook $(PLAYBOOKS_DIR)/openvpn_server.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

destroy: check_hosts ## Destroy openvpn server
	ansible-playbook $(PLAYBOOKS_DIR)/openvpn_server_destroy.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

vpnclient: mkvpnclient getvpnclient ## Create OpenVPN client certs and config and fetch (user name: OPENVPN_CLIENT)

mkvpnclient: ## Create VPN Client Certificates
	ansible -i $(INVENTORY) $(PLAYBOOKS_HOSTS) \
	                         -b -m shell -a 'cd /etc/openvpn/easy-rsa/ && ./mkclient.sh $(OPENVPN_CLIENT)'
	ansible -i $(INVENTORY) $(PLAYBOOKS_HOSTS) \
	                         -b -m shell -a 'cd /etc/openvpn/easy-rsa/ && ./mkconfig.sh $(OPENVPN_CLIENT)'

getvpnclient: ## Get VPN Client Config
	ansible -i $(INVENTORY) $(PLAYBOOKS_HOSTS) \
	                         -b -m fetch -a 'src=/etc/openvpn/easy-rsa/client-configs/$(OPENVPN_CLIENT).ovpn dest=$(THIS_BASE)/ flat=yes'

import_gpg_key: ## Import GPG key from keyserver
	gpg --keyserver $(KEYSERVER) --search-keys $(OPENVPN_CLIENT_EMAIL)

encrypt_vpnclient: import_gpg_key ## Encrypt OVPN file using gpg
	gpg --output $(THIS_BASE)/$(OPENVPN_CLIENT).ovpn.gpg --encrypt --recipient $(OPENVPN_CLIENT_EMAIL) /home/clean/ska-ser-infra-machinery/nzotho.ovpn

rm_vpnclient: ## Revoke VPN cert and remove records
	ansible -i $(INVENTORY) $(PLAYBOOKS_HOSTS) \
	                         -b -m shell -a 'cd /etc/openvpn/easy-rsa/ && ./revoke.sh $(OPENVPN_CLIENT)'

help: ## Show Help
	@echo "openvpn targets - make playbooks openvpn <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

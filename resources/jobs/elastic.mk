ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

install:
	ansible-playbook ./ansible_collections/ska_collections/elastic/playbooks/stack.yml \
	-i $(PLAYBOOKS_ROOT_DIR)/inventory.yml \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"
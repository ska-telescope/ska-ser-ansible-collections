.PHONY: help
.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
ANSIBLE_EXTRA_VARS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)
PLAYBOOKS_DIR ?= ./ansible_collections/ska_collections/gitlab_management/playbooks
PLAYBOOKS_HOSTS ?= localhost

-include $(BASE_PATH)/PrivateRules.mak

check_input_args:
ifndef GITLAB_USER_TO_MANAGE
	$(error GITLAB_USER_TO_MANAGE is undefined)
endif
ifndef GITLAB_ACCESS_TOKEN
	$(error GITLAB_ACCESS_TOKEN is undefined)
endif

add_gitlab_user: check_input_args ## Add user to SKAO default groups
	ansible-playbook $(PLAYBOOKS_DIR)/add_user.yml \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "gitlab_user_to_manage=$(GITLAB_USER_TO_MANAGE)" \
	--extra-vars "gitlab_access_token=$(GITLAB_ACCESS_TOKEN)"

remove_gitlab_user: check_input_args ## Add user to SKAO default groups
	ansible-playbook $(PLAYBOOKS_DIR)/remove_user.yml \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "gitlab_user_to_manage=$(GITLAB_USER_TO_MANAGE)" \
	--extra-vars "gitlab_access_token=$(GITLAB_ACCESS_TOKEN)"

help: ## Show Help
	@echo "Gitlab_management targets - make playbooks gitlab_management <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

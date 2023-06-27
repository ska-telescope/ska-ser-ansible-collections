.PHONY: help
.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
ANSIBLE_EXTRA_VARS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)
PLAYBOOKS_DIR ?= ./ansible_collections/ska_collections/gitlab_management/playbooks

-include $(BASE_PATH)/PrivateRules.mak

check_inputs_user:
ifndef GITLAB_USER_TO_MANAGE
	$(error GITLAB_USER_TO_MANAGE is undefined)
endif
ifndef GITLAB_ACCESS_TOKEN
	$(error GITLAB_ACCESS_TOKEN is undefined)
endif

check_inputs_repo:
ifndef NEW_GITLAB_REPO
	$(error NEW_GITLAB_REPO is undefined)
endif
ifndef GITLAB_ACCESS_TOKEN
	$(error GITLAB_ACCESS_TOKEN is undefined)
endif
ifndef GITHUB_ACCESS_TOKEN
	$(error GITHUB_ACCESS_TOKEN is undefined)
endif

add_gitlab_user: check_inputs_user ## Add user to SKAO default groups
	ansible-playbook $(PLAYBOOKS_DIR)/add_user.yml \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "gitlab_user_to_manage=$(GITLAB_USER_TO_MANAGE)" \
	--extra-vars "gitlab_access_token=$(GITLAB_ACCESS_TOKEN)"

remove_gitlab_user: check_inputs_user ## Add user to SKAO default groups
	ansible-playbook $(PLAYBOOKS_DIR)/remove_user.yml \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "gitlab_user_to_manage=$(GITLAB_USER_TO_MANAGE)" \
	--extra-vars "gitlab_access_token=$(GITLAB_ACCESS_TOKEN)"

add_gitlab_repo: check_inputs_repo ## Add repo to SKAO group
	ansible-playbook $(PLAYBOOKS_DIR)/create_repo.yml \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "gitlab_repo=$(NEW_GITLAB_REPO)" \
	--extra-vars "gitlab_access_token=$(GITLAB_ACCESS_TOKEN)" \
	--extra-vars "github_access_token=$(GITHUB_ACCESS_TOKEN)"

remove_gitlab_repo: check_inputs_repo ## Remove repo from SKAO group
	ansible-playbook $(PLAYBOOKS_DIR)/remove_repo.yml \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "gitlab_repo=$(NEW_GITLAB_REPO)" \
	--extra-vars "gitlab_access_token=$(GITLAB_ACCESS_TOKEN)"

help: ## Show Help
	@echo "Gitlab_management targets - make playbooks gitlab_management <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

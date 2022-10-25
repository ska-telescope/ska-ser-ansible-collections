.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)

-include $(BASE_PATH)/PrivateRules.mak

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

check_gitlab_runner_secrets:
ifndef GITLAB_RUNNER_REGISTRATION_TOKEN
	$(error GITLAB_RUNNER_REGISTRATION_TOKEN is undefined)
endif

vars:
	@echo "\033[36mGitlab-runner:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"
	@echo "GITLAB_RUNNER_REGISTRATION_TOKEN=$(GITLAB_RUNNER_REGISTRATION_TOKEN)"

install: check_hosts check_gitlab_runner_secrets ## Deploy gitlab-runner
	@ansible-playbook ./ansible_collections/ska_collections/gitlab_runner/playbooks/deploy.yml \
	-i $(INVENTORY) \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
	--extra-vars " \
		target_hosts=$(PLAYBOOKS_HOSTS) \
		gitlab_runner_registration_token=$(GITLAB_RUNNER_REGISTRATION_TOKEN)
	"

destroy: check_hosts check_gitlab_runner_secrets ## Destroy gitlab-runner
	@ansible-playbook ./ansible_collections/ska_collections/gitlab_runner/playbooks/undeploy.yml \
	-i $(INVENTORY) \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
	--extra-vars " \
		target_hosts=$(PLAYBOOKS_HOSTS) \
		gitlab_runner_registration_token=$(GITLAB_RUNNER_REGISTRATION_TOKEN) \
	"

help: ## Show Help
	@echo "Gitlab-runner targets - make playbooks gitlab-runner <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

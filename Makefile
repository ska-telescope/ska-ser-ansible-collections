.DEFAULT_GOAL := help

.PHONY: elastic

PLAYBOOKS_HOSTS?=all

# define overides for above variables in here
-include PrivateRules.mak

# # Fixed variables
# TIMEOUT = 86400

# # Docker and Gitlab CI variables
# RDEBUG ?= ""
# CI_ENVIRONMENT_SLUG ?= development
# CI_PIPELINE_ID ?= pipeline$(shell tr -c -d '0123456789abcdefghijklmnopqrstuvwxyz' </dev/urandom | dd bs=8 count=1 2>/dev/null;echo)
# CI_JOB_ID ?= job$(shell tr -c -d '0123456789abcdefghijklmnopqrstuvwxyz' </dev/urandom | dd bs=4 count=1 2>/dev/null;echo)
# GITLAB_USER ?= ""
# CI_BUILD_TOKEN ?= ""
# REPOSITORY_TOKEN ?= ""
# REGISTRY_TOKEN ?= ""
# GITLAB_USER_EMAIL ?= "nobody@example.com"
# DOCKER_VOLUMES ?= /var/run/docker.sock:/var/run/docker.sock
# CI_APPLICATION_TAG ?= $(shell git rev-parse --verify --short=8 HEAD)
# DOCKERFILE ?= Dockerfile
# EXECUTOR ?= docker

check-env:
ifndef ENVIRONMENT
	$(error ENVIRONMENT is undefined)
endif

vars:  ## Variables
	@echo "Current variable settings:"
	@echo "ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS)"


help:  ## show this help.
	@echo "make targets:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""; echo "make vars (+defaults):"
	@grep -E '^[0-9a-zA-Z_-]+ \?=.*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = " \\?= "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

ping:  check-env ## Ping
	ansible all -i $(PLAYBOOKS_ROOT_DIR)/inventory.yml -m ping -l $(PLAYBOOKS_HOSTS)

# If the first argument is "elastic"...
ifeq (elastic,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "elastic"
  TARGET_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(TARGET_ARGS):;@:)
endif

elastic: check-env
	$(MAKE) $(TARGET_ARGS) -f ./resources/jobs/elastic.mk
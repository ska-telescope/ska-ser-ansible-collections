.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)

PRIVATE_VARS ?= ./nexus_vars.yml
NODES ?= localhost
EXTRA_VARS ?= vault_nexus_admin_password='whatwhat' vault_nexus_user_password_gitlab='whatwhat' vault_nexus_user_password_publisher='whatwhat' vault_nexus_email_server_password='whatwhat' vault_nexus_user_password_quarantiner='whatwhat' nexus_webhook_url='http://localhost:8080' nexus_webhook_secret_key='whatwhat' nexus_apt_bionic_internal_key='whatwhat' nexus_apt_bionic_internal_key_passphrase='whatwhat' nexus_apt_bionic_quarentine_key='whatwhat' nexus_apt_bionic_quarentine_key_passphrase='whatwhat'
EXTRA_ARGS ?=
COLLECTIONS_PATHS ?= ./collections
COLLECTIONS_VERSION ?= v2.4.14
NTP_SERVER ?= 1.fedora.pool.ntp.org

# Set dir of Makefile to a variable to use later
MAKEPATH := $(abspath $(lastword $(MAKEFILE_LIST)))
BASEDIR := $(patsubst %/,%,$(dir $(MAKEPATH)))

.PHONY: vars help test k8s show lint deploy delete logs describe namespace default clean

# Fixed variables
TIMEOUT = 86400

STAGE ?= test
CI_JOB_TOKEN ?=
SKIP_TAGS ?=
RUN_TAGS ?=
V ?=

CI_ENVIRONMENT_SLUG ?= development
CI_PIPELINE_ID ?= pipeline$(shell tr -c -d '0123456789abcdefghijklmnopqrstuvwxyz' </dev/urandom | dd bs=8 count=1 2>/dev/null;echo)
CI_JOB_ID ?= job$(shell tr -c -d '0123456789abcdefghijklmnopqrstuvwxyz' </dev/urandom | dd bs=4 count=1 2>/dev/null;echo)
GITLAB_USER ?= ""
CI_BUILD_TOKEN ?= ""
REPOSITORY_TOKEN ?= ""
REGISTRY_TOKEN ?= ""
GITLAB_USER_EMAIL ?= "nobody@example.com"
DOCKER_VOLUMES ?= /var/run/docker.sock:/var/run/docker.sock
CI_APPLICATION_TAG ?= $(shell git rev-parse --verify --short=8 HEAD)
DOCKERFILE ?= Dockerfile
EXECUTOR ?= docker

# Molecule variables
MOLECULE_SCENARIO_NAME ?= default

# define overides for above variables in here
-include PrivateRules.mak

ANSIBLE_COLLECTIONS_PATHS := $(COLLECTIONS_PATHS):~/.ansible/collections:/usr/share/ansible/collections
ANSIBLE_ROLES_PATHS := $(COLLECTIONS_PATHS):$(COLLECTIONS_PATHS)/ansible_collections:~/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

vars:  ## List Variables
	@echo "Current variable settings:"
	@echo "PRIVATE_VARS=$(PRIVATE_VARS)"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "EXTRA_VARS=$(EXTRA_VARS)"
	@echo "ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS)"

uninstall:  # uninstall collections
	export DTE=`date +"%Y.%m.%d.%H%M%S"` && \
	if [ -d $(COLLECTIONS_PATHS) ]; then \
	mkdir -p $(COLLECTIONS_PATHS)-$${DTE} && \
	cp -r $(COLLECTIONS_PATHS)/* $(COLLECTIONS_PATHS)-$${DTE}/ && \
	rm -rf $(COLLECTIONS_PATHS)/*; fi

install:  ## Install dependent ansible collections
	ansible-galaxy role install -r requirements.yml -p ./collections
	ansible-galaxy collection install -r requirements.yml -p ./collections

apply-patch:  ## apply patch to upstream nexus3-oss
	# patch the nexus install for the oss edition
	if [ -f collections/ansible-thoteam.nexus3-oss/.patched ]; then \
	echo "Allready patched !"; \
	else \
	git apply --directory collections/ansible-thoteam.nexus3-oss \
		--verbose ./resources/nexus3-oss.patch  && \
	touch collections/ansible-thoteam.nexus3-oss/.patched; \
	fi

update-and-patch:  ## checkout upstream and apply patch for dev
	rm -rf nexus3-oss
	git clone git@github.com:ansible-ThoTeam/nexus3-oss.git
	make apply-patch
	cd nexus3-oss && git diff

make-patch:  ## make updated patch for upstream
	cd nexus3-oss && git diff > ../resources/nexus3-oss.patch

reinstall: uninstall install ## reinstall collections

lint: ## Lint check playbook
	yamllint -d "{extends: relaxed, rules: {line-length: {max: 256}}}" \
			--no-warnings \
			./tests/molecule \
			playbooks/roles/* \
			playbooks/*.yml
	ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS) \
	ANSIBLE_ROLES_PATH=$(ANSIBLE_ROLES_PATHS) \
	ansible-lint --exclude $${HOME}/.cache --exclude .cache --exclude ./collections --exclude ./collections/ansible-thoteam.nexus3-oss --exclude $${HOME}/.ansible/roles playbooks/roles/*  playbooks/*.yml

deploy: apply-patch  ## Install nexus
	ANSIBLE_COLLECTIONS_PATH=$(ANSIBLE_COLLECTIONS_PATHS) \
	ANSIBLE_ROLES_PATH=$(ANSIBLE_ROLES_PATHS) \
	ansible-playbook -i $(INVENTORY) ./ansible_collections/ska_collections/nexus/playbooks/deploy.yml \
	-e @$(PRIVATE_VARS) \
	$(EXTRA_ARGS) \
	--extra-vars="$(EXTRA_VARS)" $(V)

docker_test:
	docker tag busybox:latest artefact.skatelescope.org/test/busybox:latest || true
	docker push artefact.skatelescope.org/test/busybox:latest

raw_test:
	curl -v -u publisher:$(PUBLISHER_PASSWD) --upload-file ./README.md https://artefact.skatelescope.org/repository/raw-internal/test/CAR-README.md

link:
	rm -f tests/molecule/roles
	ln -s ../../playbooks/roles tests/molecule/roles

test: reinstall link apply-patch  ## run molecule tests locally outside gitlab-runner
	BASE=$$(pwd); \
	mkdir -p $${BASE}/build/reports; \
	rm -rf $${BASE}/tests/.coverage* $${BASE}/tests/.pytest_cache $${BASE}/build/reports/*; \
	export ANSIBLE_COLLECTIONS_PATHS=$${BASE}/collections \
	       ANSIBLE_COLLECTIONS_PATH=$${BASE}/collections \
	       ANSIBLE_ROLES_PATH=$${BASE}/collections; \
	export CURDIR=$(CURDIR); \
	export NTP_SERVER=$(NTP_SERVER); \
	cd tests && pytest \
			--junitxml=$${BASE}/build/reports/unit-tests.xml \
			--cov \
			--cov-report term \
			--cov-report html:$${BASE}/build/reports/htmlcov \
			--cov-report xml:$${BASE}/build/reports/code-coverage.xml \
	        --log-file=$${BASE}/build/reports/pytest-logs.txt -v; \
		   RC=$$?; \
		   echo "###### pytest logs #########"; \
		   cat $${BASE}/build/reports/pytest-logs.txt; \
		   echo "RC: $${RC}"; \
           echo "###### code coverage #######"; \
           echo cat $${BASE}/build/reports/code-coverage.xml; \
 		   echo "###### unit tests #######"; \
		   cat $${BASE}/build/reports/unit-tests.xml; \
	exit $${RC}

molecule: reinstall link apply-patch ## run molecule tests but don't destroy container
	BASE=$$(pwd); \
	export ANSIBLE_ROLES_PATH=$${BASE}/roles;  env | grep ANSIBLE; \
	export CI_JOB_TOKEN=$(CI_JOB_TOKEN); \
	cd tests && MOLECULE_NO_LOG="false" molecule --debug test --destroy=never --scenario-name=$(MOLECULE_SCENARIO_NAME)

verify: ## rerun molecule verify - must run make molecule first
	BASE=$$(pwd); \
	export ANSIBLE_COLLECTIONS_PATHS=$${BASE}/collections \
	       ANSIBLE_COLLECTIONS_PATH=$${BASE}/collections; \
	export ANSIBLE_ROLES_PATH=$${BASE}/roles;  env | grep ANSIBLE; \
	cd tests && MOLECULE_NO_LOG="false" molecule verify --scenario-name=$(MOLECULE_SCENARIO_NAME)

destroy: ## run molecule destroy - cleanup after make molecule
	BASE=$$(pwd); \
	export ANSIBLE_COLLECTIONS_PATHS=$${BASE}/collections \
	       ANSIBLE_COLLECTIONS_PATH=$${BASE}/collections; \
	export ANSIBLE_ROLES_PATH=$${BASE}/roles;  env | grep ANSIBLE; \
	export CI_JOB_TOKEN=$(CI_JOB_TOKEN); \
	cd tests && MOLECULE_NO_LOG="false" molecule destroy

rtest:  ## run make $(STAGE) using gitlab-runner - default: test
	BASE=$$(pwd); \
	if [ -n "$(RDEBUG)" ]; then DEBUG_LEVEL=debug; else DEBUG_LEVEL=warn; fi && \
	gitlab-runner --log-level $${DEBUG_LEVEL} exec $(EXECUTOR) \
    --docker-volumes  $(DOCKER_VOLUMES) \
    --docker-pull-policy always \
	--timeout $(TIMEOUT) \
	--env "GITLAB_USER=$(GITLAB_USER)" \
	--env "CI_BUILD_TOKEN=$(CI_BUILD_TOKEN)" \
	--env "CI_JOB_TOKEN=$(CI_JOB_TOKEN)" \
	--env "NTP_SERVER=$(NTP_SERVER)" \
	--env "TRACE=1" \
	--env "DEBUG=1" \
	$(STAGE) || true

help: ## Show Help
	@echo "Nexus targets - make playbooks nexus <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
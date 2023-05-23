.PHONY: check-hosts vars calico-install calico-uninstall calico-uninstall-manifest calico-test \
install-base management-cluster install build-management-cluster create-workload-cluster get-workload-kubeconfig \
get-workload-inventory get-workload-cluster destroy-workload-cluster destroy-management-cluster imagebuilder help
.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
ANSIBLE_EXTRA_VARS ?=
PLAYBOOKS_DIR ?= ./ansible_collections/ska_collections
TESTS_DIR ?= ./ansible_collections/ska_collections/clusterapi/tests

DELEGATE_HOSTS ?= localhost

-include $(BASE_PATH)/PrivateRules.mak

check-hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

CAPI_APPLY ?= false ## Apply workload cluster: true or false - default: false
CAPI_TAGS ?= all ## Ansible tags to run in post deployment processing

vars:
	@echo "\033[36mclusterapi:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"
	@echo "ANSIBLE_PLAYBOOK_ARGUMENTS=$(ANSIBLE_PLAYBOOK_ARGUMENTS)"
	@echo "ANSIBLE_EXTRA_VARS=$(ANSIBLE_EXTRA_VARS)"
	@echo "ANSIBLE_SSH_ARGS=$(ANSIBLE_SSH_ARGS)"
	@echo "CAPI_APPLY=$(CAPI_APPLY)"
	@echo "CAPI_TAGS=$(CAPI_TAGS)"

calico-install: check-hosts  ## Install Calico
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/calico-install.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

calico-uninstall: check-hosts  ## Uninstall Calico
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/calico-uninstall.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

calico-uninstall-manifest:  ## Uninstall calico deployed using manifest
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/calico-uninstall-manifest.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"

calico-test: check-hosts ## Test calico network
	ansible-playbook $(TESTS_DIR)/calico.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

install-base: check-hosts  ## Install base for management server
	ansible-playbook $(PLAYBOOKS_DIR)/docker_base/playbooks/containers.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

create-management-cluster: check-hosts  ## Install Minikube management cluster
	ansible-playbook $(PLAYBOOKS_DIR)/minikube/playbooks/minikube.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "build"

install: check-hosts  ## Install clusterapi component
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/clusterapi.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

build-management-cluster: install-base create-management-cluster install ## Complete steps for building clusterapi management server

# Leaving CAPI_APPLY so that we can easily not run the apply to check the manifest
# while we make the playbooks mature
create-workload-cluster: check-hosts  ## Template workload manifest and deploy the cluster
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/create-workload.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS) " \
	--extra-vars "capi_apply_manifest=$(CAPI_APPLY)"

get-workload-kubeconfig: check-hosts  ## Get workload cluster kubeconfig
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/get-workload-kubeconfig.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "delegate_hosts=$(DELEGATE_HOSTS)"

get-workload-inventory: check-hosts  ## Get workload cluster inventory
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/get-workload-inventory.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

get-workload-cluster: check-hosts get-workload-kubeconfig get-workload-inventory  ## Gets kubeconfig and inventory of the cluster

destroy-workload-cluster: check-hosts  ## Destroy the workload cluster
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/destroy-workload.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

destroy-management-cluster:  ## Destroy the management cluster
	ansible-playbook $(PLAYBOOKS_DIR)/minikube/playbooks/minikube.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "destroy"

imagebuilder:  ## Build and upload OS Image Builder Kubernetes image
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/imagebuilder.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

help: ## Show Help
	@echo "Clusterapi targets - make playbooks clusterapi <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
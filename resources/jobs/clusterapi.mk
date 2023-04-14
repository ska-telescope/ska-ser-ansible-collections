-include $(BASE_PATH)/PrivateRules.mak

clusterapi-check-hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
ANSIBLE_EXTRA_VARS ?=
PLAYBOOKS_DIR ?= ./ansible_collections/ska_collections
TESTS_DIR ?= ./ansible_collections/ska_collections/clusterapi/tests

CAPI_CLUSTER_TYPE ?= capo
CAPI_APPLY ?= false ## Apply workload cluster: true or false - default: false
CAPI_AC_BRANCH ?= main ## Ansible Collections branch to apply to workload cluster
CAPI_CLUSTER ?= capo-test ## Name of workload cluster to create
CAPI_TAGS ?= all ## Ansible tags to run in post deployment processing

CALICO_TEST_NODES ?= ["minikube"]

.DEFAULT_GOAL := clusterapi

clusterapi-check-cluster-type:
ifndef CAPI_CLUSTER_TYPE
	$(error CAPI_CLUSTER_TYPE is undefined - MUST be 'capo')
endif

vars:
	@echo "\033[36mclusterapi:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"
	@echo "ANSIBLE_PLAYBOOK_ARGUMENTS=$(ANSIBLE_PLAYBOOK_ARGUMENTS)"
	@echo "ANSIBLE_EXTRA_VARS=$(ANSIBLE_EXTRA_VARS)"
	@echo "ANSIBLE_SSH_ARGS=$(ANSIBLE_SSH_ARGS)"
	@echo "CAPI_CLUSTER=$(CAPI_CLUSTER)"
	@echo "CAPI_APPLY=$(CAPI_APPLY)"
	@echo "CAPI_AC_BRANCH=$(CAPI_AC_BRANCH)"

calico-install: clusterapi-check-hosts  ## Install Calico
	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="$(ANSIBLE_SSH_ARGS)" \
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/calico-install.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "k8s_kubeconfig=$(KUBECONFIG)" \
	--extra-vars "capi_cluster=$(CAPI_CLUSTER)" \
	--tags "$(TAGS)"

calico-uninstall: clusterapi-check-hosts  ## Uninstall Calico
	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="$(ANSIBLE_SSH_ARGS)" \
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/calico-uninstall.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS) k8s_kubeconfig=$(KUBECONFIG)"

calico-test: clusterapi-check-hosts ## Test calico network
	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="$(ANSIBLE_SSH_ARGS)" \
	ansible-playbook $(TESTS_DIR)/calico.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "capi_cluster=$(CAPI_CLUSTER)"

calico-uninstall-manifest:  ## Uninstall calico deployed using manifest
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/calico-uninstall-manifest.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "capi_cluster=$(CAPI_CLUSTER)" \
	--extra-vars "k8s_kubeconfig=$(K8S_KUBECONFIG)" \
	--tags "$(TAGS)" \
	-vv

clusterapi-install-base: clusterapi-check-hosts  ## Install base for management server
	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="$(ANSIBLE_SSH_ARGS)" \
	ansible-playbook $(PLAYBOOKS_DIR)/docker_base/playbooks/containers.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=management-cluster" \
	--limit "management-cluster"

clusterapi-management: clusterapi-check-hosts  ## Install Minikube management cluster
	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="$(ANSIBLE_SSH_ARGS)" \
	ansible-playbook $(PLAYBOOKS_DIR)/minikube/playbooks/minikube.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=management-cluster" \
	--limit "management-cluster" --tags "build" -vv

clusterapi: clusterapi-check-hosts  ## Install clusterapi component
	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="$(ANSIBLE_SSH_ARGS)" \
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/clusterapi.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=management-cluster" \
	--limit "management-cluster"

clusterapi-build-management-server:  ## Complete steps for building clusterapi management server
	make clusterapi clusterapi-install-base
	make clusterapi clusterapi-management
	make clusterapi clusterapi

clusterapi-createworkload: clusterapi-check-cluster-type  ## Template workload manifest and deploy
	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="$(ANSIBLE_SSH_ARGS)" \
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/createworkload.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=management-cluster" \
	--extra-vars "capi_cluster=$(CAPI_CLUSTER)" \
	--extra-vars "capi_kustomize_overlay=$(CAPI_CLUSTER_TYPE)" \
	--extra-vars '{"cluster_apply": $(CAPI_APPLY)}' \
	--extra-vars 'capi_collections_branch=$(CAPI_AC_BRANCH)' \
	--limit "management-cluster" -vv
	
clusterapi-scale-workload: clusterapi-check-cluster-type  ## Template workload manifest and deploy
	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="$(ANSIBLE_SSH_ARGS)" \
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/scale-workload.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "capi_cluster=$(CAPI_CLUSTER)" \
	-vv

clusterapi-delete-workload: clusterapi-check-cluster-type  ## Template workload manifest and deploy
	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="$(ANSIBLE_SSH_ARGS)" \
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/delete-workload.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "capi_cluster=$(CAPI_CLUSTER)" \
	-vv

clusterapi-workload-kubeconfig: clusterapi-check-cluster-type  ## Post deployment get workload kubeconfig
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/get-kubeconfig.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "capi_cluster=$(CAPI_CLUSTER)" \
	--limit "management-cluster" -vv

clusterapi-workload-inventory: clusterapi-check-cluster-type  ## Post deployment get workload inventory
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/get-inventory.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "capi_cluster=$(CAPI_CLUSTER)" \
	--limit "management-cluster" -vv

clusterapi-post-deployment: clusterapi-check-cluster-type  ## Post deployment for workload cluster

	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/calico-install.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=management-cluster" \
	--extra-vars "capi_cluster=$(CAPI_CLUSTER)" \
	--limit "management-cluster" \
	--tags "$(CAPI_TAGS)" \
	-vv

clusterapi-destroy-management:  ## Destroy Minikube management cluster
	ansible-playbook $(PLAYBOOKS_DIR)/minikube/playbooks/minikube.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--limit "management-cluster" --tags "destroy"

clusterapi-imagebuilder:  ## Build and upload OS Image Builder Kubernetes image
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/imagebuilder.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--limit "management-cluster" -v

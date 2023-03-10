-include $(BASE_PATH)/PrivateRules.mak

clusterapi-check-hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

clusterapi-check-cluster-type:
ifndef CLUSTERAPI_CLUSTER_TYPE
	$(error CLUSTERAPI_CLUSTER_TYPE is undefined - MUST be 'capo' or 'byoh')
endif
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
ANSIBLE_EXTRA_VARS ?=
PLAYBOOKS_DIR ?= ./ansible_collections/ska_collections

CLUSTERAPI_APPLY ?= false ## Apply workload cluster: true or false - default: false
CLUSTERAPI_AC_BRANCH ?= main ## Ansible Collections branch to apply to workload cluster
CLUSTERAPI_CLUSTER ?= test ## Name of workload cluster to create
CLUSTERAPI_TAGS ?= all ## Ansible tags to run in post deployment processing

.DEFAULT_GOAL := clusterapi

vars:
	@echo "\033[36mclusterapi:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"
	@echo "ANSIBLE_PLAYBOOK_ARGUMENTS=$(ANSIBLE_PLAYBOOK_ARGUMENTS)"
	@echo "ANSIBLE_EXTRA_VARS=$(ANSIBLE_EXTRA_VARS)"
	@echo "ANSIBLE_SSH_ARGS=$(ANSIBLE_SSH_ARGS)"
	@echo "CLUSTERAPI_CLUSTER=$(CLUSTERAPI_CLUSTER_TYPE)-$(CLUSTERAPI_CLUSTER)"
	@echo "CLUSTERAPI_APPLY=$(CLUSTERAPI_APPLY)"
	@echo "CLUSTERAPI_AC_BRANCH=$(CLUSTERAPI_AC_BRANCH)"

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

clusterapi-build-management-server:  # Complete stesp for building clusterapi management server
	make clusterapi-install-base
	make clusterapi-management
	make clusterapi

CLUSTERAPI_DNS_SERVERS?=
clusterapi-createworkload: clusterapi-check-cluster-type  ## Template workload manifest and deploy
	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="$(ANSIBLE_SSH_ARGS)" \
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/createworkload.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=management-cluster" \
	--extra-vars "capi_cluster=$(CLUSTERAPI_CLUSTER_TYPE)-$(CLUSTERAPI_CLUSTER)" \
	--extra-vars "capi_kustomize_overlay=$(CLUSTERAPI_CLUSTER_TYPE)" \
	--extra-vars '{"cluster_apply": $(CLUSTERAPI_APPLY)}' \
	--extra-vars 'capi_collections_branch=$(CLUSTERAPI_AC_BRANCH)' \
	--limit "management-cluster" -vv

clusterapi-workload-kubeconfig: clusterapi-check-cluster-type  ## Post deployment get workload kubeconfig
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/get-kubeconfig.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "capi_cluster=$(CLUSTERAPI_CLUSTER_TYPE)-$(CLUSTERAPI_CLUSTER)" \
	--limit "management-cluster" -vv

clusterapi-post-deployment: clusterapi-check-cluster-type  ## Post deployment for workload cluster

	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/calico.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=management-cluster" \
	--extra-vars "capi_cluster=$(CLUSTERAPI_CLUSTER_TYPE)-$(CLUSTERAPI_CLUSTER)" \
	--limit "management-cluster" \
	--tags "$(CLUSTERAPI_TAGS)" \
	-vv

#     #   echo "Controlplane initialise: cloud provider config"
#     #   echo "$OPENSTACK_CLOUD_PROVIDER_CONF_B64" | base64 -d > /etc/kubernetes/cloud.conf
# 	#   cloud_provider_config: /etc/kubernetes/cloud.conf

ifneq (,$(findstring cloudprovider,$(CLUSTERAPI_TAGS)))
    # cloudprovider is a target - avoid undefined ansible vars issue with tags
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/cloud-provider.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=management-cluster" \
	--extra-vars "capi_cluster=$(CLUSTERAPI_CLUSTER_TYPE)-$(CLUSTERAPI_CLUSTER)" \
	--extra-vars "ingress_nginx_version=${NGINX_VERSION}" \
	--extra-vars "ingress_lb_suffix=${CLUSTER_NAME}" \
	--limit "management-cluster" \
	--tags "$(CLUSTERAPI_TAGS)" \
	-vv
endif

clusterapi-byoh-reset:  ## Reset workload hosts
	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="$(ANSIBLE_SSH_ARGS)" \
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/reset-byoh.yml \
	-i $(INVENTORY) --limit workload-cluster $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=workload-cluster" -v

clusterapi-byoh-init:  ## Initialise byoh workload hosts
	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="$(ANSIBLE_SSH_ARGS)" \
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/init-hosts.yml \
	-i $(INVENTORY) --limit workload-cluster $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=workload-cluster" -v

clusterapi-byoh-engine:  ## Deploy byoh container engine on workload hosts
	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="$(ANSIBLE_SSH_ARGS)" \
	ansible-playbook $(PLAYBOOKS_DIR)/docker_base/playbooks/containers.yml \
	-i $(INVENTORY) --limit workload-cluster $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=workload-cluster" -v

clusterapi-byoh-agent:  ## Deploy byoh agent and tokens to workload hosts
	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="$(ANSIBLE_SSH_ARGS)" \
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/byoh.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=workload-cluster" -v

clusterapi-byoh:  ## Prepare byoh nodes
	make clusterapi-byoh-init
	make clusterapi-byoh-engine
	make clusterapi-byoh-agent

clusterapi-destroy-management:  ## Destroy Minikube management cluster
	ansible-playbook $(PLAYBOOKS_DIR)/minikube/playbooks/minikube.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--limit "management-cluster" --tags "destroy"

clusterapi-byoh-port-security:  ## Unset port security on byohosts
	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="$(ANSIBLE_SSH_ARGS)" \
	OS_CLOUD=skatechops \
	ansible-playbook $(PLAYBOOKS_DIR)/metallb/playbooks/metallb_openstack.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=localhost" -v

clusterapi-imagebuilder:  ## Build and upload OS Image Builder Kubernetes image
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/imagebuilder.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--limit "management-cluster" -v

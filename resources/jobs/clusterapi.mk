
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
CLUSTERAPI_AC_BRANCH ?= bang-105-add-byoh ## Ansible Collections branch to apply to workload cluster
CLUSTERAPI_CLUSTER ?= test ## Name of workload cluster to create


.DEFAULT_GOAL := clusterapi

vars:
	@echo "\033[36mclusterapi:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"
	@echo "ANSIBLE_PLAYBOOK_ARGUMENTS=$(ANSIBLE_PLAYBOOK_ARGUMENTS)"
	@echo "ANSIBLE_EXTRA_VARS=$(ANSIBLE_EXTRA_VARS)"
	@echo "CLUSTERAPI_CLUSTER=$(CLUSTERAPI_CLUSTER)"
	@echo "CLUSTERAPI_APPLY=$(CLUSTERAPI_APPLY)"
	@echo "CLUSTERAPI_AC_BRANCH=$(CLUSTERAPI_AC_BRANCH)"

clusterapi-install-base:  ## Install base for management server
	ansible-playbook $(PLAYBOOKS_DIR)/docker_base/playbooks/containers.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--limit "management-cluster"

# clusterapi-management:
clusterapi-management: clusterapi-install-base  ## Install Minikube management cluster
	ansible-playbook $(PLAYBOOKS_DIR)/minikube/playbooks/minikube.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--limit "management-cluster" --tags "build"

# clusterapi:
clusterapi: clusterapi-check-hosts clusterapi-management clusterapi-velero-backups  ## Install clusterapi component
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/clusterapi.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--limit "management-cluster"

clusterapi-createworkload: clusterapi-check-cluster-type  ## Template workload manifest and deploy
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/createworkload.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "capi_cluster=$(CLUSTERAPI_CLUSTER)" \
	--extra-vars "capi_kustomize_overlay=$(CLUSTERAPI_CLUSTER_TYPE)" \
	--extra-vars '{"cluster_apply": $(CLUSTERAPI_APPLY)}' \
	--extra-vars 'capi_collections_branch=$(CLUSTERAPI_AC_BRANCH)' \
	--limit "management-cluster"

clusterapi-byoh-reset:  ## Reset workload hosts
	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="-o ControlPersist=30m -o StrictHostKeyChecking=no -F $(PLAYBOOKS_ROOT_DIR)/ssh.config" \
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/reset-byoh.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" -v

clusterapi-byoh-port-security:  ## Unset port security on byohosts
	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="-o ControlPersist=30m -o StrictHostKeyChecking=no -F $(PLAYBOOKS_ROOT_DIR)/ssh.config" \
	OS_CLOUD=skatechops \
	ansible-playbook $(PLAYBOOKS_DIR)/metallb/playbooks/metallb_openstack.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=localhost" -v

clusterapi-byoh:  ## Deploy byoh agent and tokens to workload hosts
	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="-o ControlPersist=30m -o StrictHostKeyChecking=no -F $(PLAYBOOKS_ROOT_DIR)/ssh.config" \
	ansible-playbook $(PLAYBOOKS_DIR)/docker_base/playbooks/containerd.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" -v

	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="-o ControlPersist=30m -o StrictHostKeyChecking=no -F $(PLAYBOOKS_ROOT_DIR)/ssh.config" \
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/byoh.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" -v

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

clusterapi-velero-backups:  ## Configure Velero backups on Minikube management cluster
	ansible-playbook $(PLAYBOOKS_DIR)/minikube/playbooks/velero_backups.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "cloud_config=$(CLUSTERAPI_CLOUD_CONFIG)" \
	--extra-vars "cloud=$(CLUSTERAPI_CLOUD)" \
	--limit "management-cluster"

# Notes for velero restore
# velero restore create test \
# --from-backup  every6h-20221021144151 \
# --existing-resource-policy=update \
# --exclude-namespaces kube-system,ingress-nginx,kube-node-lease,kube-public,metallb-system,velero  \
# --include-cluster-resources=true

# check restore
# velero restore describe test

# get logs
# kubectl -n velero logs $(kubectl -n velero get pods -l component=velero  -o name) > logs.txt

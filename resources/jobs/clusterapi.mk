
clusterapi-check-hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

clusterapi-check-cluster-type:
ifndef CLUSTERAPI_CLUSTER_TYPE
	$(error CLUSTERAPI_CLUSTER_TYPE is undefined - MUST be 'capo' or 'byoh')
endif

CLUSTERAPI_APPLY ?= false ## Apply workload cluster: true or false - default: false
CLUSTERAPI_AC_BRANCH ?= bang-105-add-byoh


.DEFAULT_GOAL := clusterapi

vars:
	@echo "\033[36mclusterapi:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"

clusterapi-install-base:  ## Install base for management server
	ansible-playbook ./ansible_collections/ska_collections/docker_base/playbooks/containers.yml \
	-i $(INVENTORY) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--limit "management-cluster"

# clusterapi-management:
clusterapi-management: clusterapi-install-base  ## Install Minikube management cluster
	ansible-playbook ./ansible_collections/ska_collections/minikube/playbooks/minikube.yml \
	-i $(INVENTORY) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--limit "management-cluster" --tags "build"

# clusterapi:
clusterapi: clusterapi-check-hosts clusterapi-management clusterapi-velero-backups  ## Install clusterapi component
	ansible-playbook ./ansible_collections/ska_collections/clusterapi/playbooks/clusterapi.yml \
	-i $(INVENTORY) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--limit "management-cluster"

clusterapi-createworkload: clusterapi-check-cluster-type  ## Template workload manifest and deploy
	ansible-playbook ./ansible_collections/ska_collections/clusterapi/playbooks/createworkload.yml \
	-i $(INVENTORY) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "capi_kustomize_overlay=$(CLUSTERAPI_CLUSTER_TYPE)" \
	--extra-vars '{"cluster_apply": $(CLUSTERAPI_APPLY)}' \
	--extra-vars '{"capi_cluster_extra_vars": {$(CLUSTERAPI_CLUSTER_EXTRA_VARS)} }' \
	--extra-vars 'capi_collections_branch=$(CLUSTERAPI_AC_BRANCH)' \
	--limit "management-cluster"

clusterapi-byoh:  ## Deploy byoh agent and tokens to workload hosts
	# ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	# ANSIBLE_SSH_ARGS="-o ControlPersist=30m -o StrictHostKeyChecking=no -F $(PLAYBOOKS_ROOT_DIR)/ssh.config" \
	# ansible-playbook ./ansible_collections/ska_collections/docker_base/playbooks/containerd.yml \
	# -i $(INVENTORY) \
	# --extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" -v

	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="-o ControlPersist=30m -o StrictHostKeyChecking=no -F $(PLAYBOOKS_ROOT_DIR)/ssh.config" \
	ansible-playbook ./ansible_collections/ska_collections/clusterapi/playbooks/byoh.yml \
	-i $(INVENTORY) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" -v

clusterapi-destroy-management:  ## Destroy Minikube management cluster
	ansible-playbook ./ansible_collections/ska_collections/minikube/playbooks/minikube.yml \
	-i $(INVENTORY) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--limit "management-cluster" --tags "destroy"

clusterapi-imagebuilder:  ## Build and upload OS Image Builder Kubernetes image
	ansible-playbook ./ansible_collections/ska_collections/clusterapi/playbooks/imagebuilder.yml \
	-i $(INVENTORY) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--limit "management-cluster" -v

clusterapi-velero-backups:  ## Configure Velero backups on Minikube management cluster
	ansible-playbook ./ansible_collections/ska_collections/minikube/playbooks/velero_backups.yml \
	-i $(INVENTORY) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "cloud_config=$(CLUSTERAPI_CLOUD_CONFIG)" \
	--extra-vars "cloud=$(CLUSTERAPI_CLOUD)" \
	--limit "management-cluster"

# velero restore
# velero restore create test \
# --from-backup  every6h-20221021144151 \
# --existing-resource-policy=update \
# --exclude-namespaces kube-system,ingress-nginx,kube-node-lease,kube-public,metallb-system,velero  \
# --include-cluster-resources=true

# check restore
# velero restore describe test

# get logs
# kubectl -n velero logs $(kubectl -n velero get pods -l component=velero  -o name) > logs.txt

#

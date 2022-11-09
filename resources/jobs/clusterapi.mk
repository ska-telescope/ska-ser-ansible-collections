ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

.DEFAULT_GOAL := clusterapi

clusterapi-install-base:  ## Install base for management server
	ansible-playbook ./ansible_collections/ska_collections/docker_base/playbooks/containers.yml \
	-i $(PLAYBOOKS_ROOT_DIR) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--limit "management-cluster"

clusterapi-management: clusterapi-install-base  ## Install Minikube management cluster
	ansible-playbook ./ansible_collections/ska_collections/minikube/playbooks/minikube.yml \
	-i $(PLAYBOOKS_ROOT_DIR) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--limit "management-cluster" --tags "build"

# clusterapi:
clusterapi: clusterapi-management clusterapi-velero-backups  ## Install clusterapi component
	ansible-playbook ./ansible_collections/ska_collections/clusterapi/playbooks/clusterapi.yml \
	-i $(PLAYBOOKS_ROOT_DIR) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--limit "management-cluster"

clusterapi-createworkload:  ## Template workload manifest and deploy
	ansible-playbook ./ansible_collections/ska_collections/clusterapi/playbooks/createworkload.yml \
	-i $(PLAYBOOKS_ROOT_DIR) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--limit "management-cluster"

clusterapi-destroy-management:  ## Destroy Minikube management cluster
	ansible-playbook ./ansible_collections/ska_collections/minikube/playbooks/minikube.yml \
	-i $(PLAYBOOKS_ROOT_DIR) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--limit "management-cluster" --tags "destroy"

clusterapi-imagebuilder:  ## Build and upload OS Image Builder Kubernetes image
	ansible-playbook ./ansible_collections/ska_collections/clusterapi/playbooks/imagebuilder.yml \
	-i $(PLAYBOOKS_ROOT_DIR) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--limit "management-cluster" -v

clusterapi-velero-backups:  ## Configure Velero backups on Minikube management cluster
	ansible-playbook ./ansible_collections/ska_collections/minikube/playbooks/velero_backups.yml \
	-i $(PLAYBOOKS_ROOT_DIR) \
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

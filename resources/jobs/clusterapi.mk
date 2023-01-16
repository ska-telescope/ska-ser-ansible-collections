
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
	@echo "CLUSTERAPI_CLUSTER=$(CLUSTERAPI_CLUSTER_TYPE)-$(CLUSTERAPI_CLUSTER)"
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

clusterapi-createworkload-manifest: clusterapi-check-cluster-type  ## Template workload manifest and deploy
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/createworkload.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "capi_cluster=$(CLUSTERAPI_CLUSTER_TYPE)-$(CLUSTERAPI_CLUSTER)" \
	--extra-vars "capi_kustomize_overlay=$(CLUSTERAPI_CLUSTER_TYPE)" \
	--extra-vars '{"cluster_apply": $(CLUSTERAPI_APPLY)}' \
	--extra-vars 'capi_collections_branch=$(CLUSTERAPI_AC_BRANCH)' \
	--limit "management-cluster"

clusterapi-workload-kubeconfig: clusterapi-check-cluster-type  ## Post deployment get workload kubeconfig
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/get-kubeconfig.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "capi_cluster=$(CLUSTERAPI_CLUSTER_TYPE)-$(CLUSTERAPI_CLUSTER)" \
	--limit "management-cluster" -vv

clusterapi-post-deployment: clusterapi-check-cluster-type  ## Post deployment for workload cluster

	# ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/standardprovisioner.yml \
	# -i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	# --extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	# --extra-vars "capi_cluster=$(CLUSTERAPI_CLUSTER_TYPE)-$(CLUSTERAPI_CLUSTER)" \
	# --limit "management-cluster" \
	# -vv

    # #   echo "Controlplane initialise: cloud provider config"
    # #   echo "$OPENSTACK_CLOUD_PROVIDER_CONF_B64" | base64 -d > /etc/kubernetes/cloud.conf
	# #   cloud_provider_config: /etc/kubernetes/cloud.conf

	# ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/cloud-provider.yml \
	# -i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	# --extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	# --extra-vars "capi_cluster=$(CLUSTERAPI_CLUSTER_TYPE)-$(CLUSTERAPI_CLUSTER)" \
	# --extra-vars "ingress_nginx_version=${NGINX_VERSION}" \
	# --extra-vars "ingress_lb_suffix=${CLUSTER_NAME}" \
	# --limit "management-cluster" \
	# -vv

	# # --extra-vars 'metallb_version=0.13.7 metallb_namespace=metallb-system metallb_addresses="10.100.10.1-10.100.253.254"'
	# ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/metallb.yml \
	# -i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	# --extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	# --extra-vars "capi_cluster=$(CLUSTERAPI_CLUSTER_TYPE)-$(CLUSTERAPI_CLUSTER)" \
	# --limit "management-cluster" \
	# -vv

	# # --extra-vars 'ingress_nginx_version: 1.3.1 ingress_lb_suffix: "{{ capi_cluster }}"'
	# ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/ingress.yml \
	# -i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	# --extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	# --extra-vars "capi_cluster=$(CLUSTERAPI_CLUSTER_TYPE)-$(CLUSTERAPI_CLUSTER)" \
	# --limit "management-cluster" \
	# -vv

	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/rookio.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "capi_cluster=$(CLUSTERAPI_CLUSTER_TYPE)-$(CLUSTERAPI_CLUSTER)" \
	--limit "management-cluster" \
	-vv

    #   cat <<EOF > run-play.sh
    #   #!/usr/bin/bash
    #   echo "run-play.sh args are: \$*"
    #   cd /usr/src/ska-ser-ansible-collections
    #   export THIS_BASE=$(pwd)
    #   export PLAYBOOKS_HOSTS=clusterapi
    #   export ANSIBLE_COLLECTIONS_PATHS="$THIS_BASE:$HOME/.ansible/collections:/usr/share/ansible/collections"
    #   export KUBECONFIG="/etc/kubernetes/admin.conf"
    #   ANSIBLE_CONFIG="$THIS_BASE/datacentres/production/installation/ansible.cfg"
    #   ansible-playbook \
    #     --connection=local \
    #     --inventory 127.0.0.1, \
    #     --limit 127.0.0.1 \
    #      --become \
    #     $THIS_BASE/ansible_collections/ska_collections/clusterapi/playbooks/\$1 \
    #      --inventory /usr/src/ska-ser-ansible-collections/ansible_hosts \$${@:2}
    #   EOF
    #   chmod a+x run-play.sh
    #   cat run-play.sh





    #   ## extract all for post deployment

    #   echo "Running the cluster initialisation: RookIO"
    #   /usr/src/ska-ser-ansible-collections/run-play.sh rookio.yml \
    #     -e "rook_version=${ROOK_VERSION}" \
    #     -e "rook_namespace="${ROOK_NAMESPACE}" \
    #     -e "kube_namespace="${KUBE_NAMESPACE}" \
    #     -e "namespace="${ROOK_NAMESPACE}" \
    #     -e "rook_external_fsid="${ROOK_EXTERNAL_FSID}" \
    #     -e "rook_external_admin_secret="${ROOK_EXTERNAL_ADMIN_SECRET}" \
    #     -e "rook_external_admin_key="${ROOK_EXTERNAL_ADMIN_KEY}" \
    #     -e "rook_external_ceph_mon_data="${ROOK_EXTERNAL_CEPH_MON_DATA}" \
    #     -e "rook_external_ceph_monitors="${ROOK_EXTERNAL_CEPH_MONITORS}" \
    #     -e "rook_rbd_pool_name="${RBD_POOL_NAME}" \
    #     -e "rook_rgw_pool_prefix="${RGW_POOL_PREFIX}" \
    #     -e "rook_csi_rbd_node_secret_name="${CSI_RBD_NODE_SECRET_NAME}" \
    #     -e "rook_csi_rbd_provisioner_secret_name="${CSI_RBD_PROVISIONER_SECRET_NAME}" \
    #     -e "rook_csi_cephfs_node_secret_name="${CSI_CEPHFS_NODE_SECRET_NAME}" \
    #     -e "rook_csi_cephfs_provisioner_secret_name="${CSI_CEPHFS_PROVISIONER_SECRET_NAME}" \
    #     -e "rook_csi_rbd_node_secret="${CSI_RBD_NODE_SECRET}" \
    #     -e "rook_csi_rbd_provisioner_secret="${CSI_RBD_PROVISIONER_SECRET}" \
    #     -e "rook_csi_cephfs_node_secret="${CSI_CEPHFS_NODE_SECRET}" \
    #     -e "rook_csi_cephfs_provisioner_secret="${CSI_CEPHFS_PROVISIONER_SECRET}" \
    #     -vv





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
	# ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	# ANSIBLE_SSH_ARGS="-o ControlPersist=30m -o StrictHostKeyChecking=no -F $(PLAYBOOKS_ROOT_DIR)/ssh.config" \
	# ansible-playbook $(PLAYBOOKS_DIR)/docker_base/playbooks/containerd.yml \
	# -i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	# --extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" -v

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


# velero restore create test \
# --from-backup  every6h-20230110020153 \
# --existing-resource-policy=update \
# --exclude-namespaces kube-system,ingress-nginx,kube-node-lease,kube-public,metallb-system,velero  \
# --include-cluster-resources=true
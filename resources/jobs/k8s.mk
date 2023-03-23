-include $(BASE_PATH)/PrivateRules.mak

k8s-check-hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

ANSIBLE_PLAYBOOK_ARGUMENTS ?=
ANSIBLE_EXTRA_VARS ?=
PLAYBOOKS_DIR ?= ./ansible_collections/ska_collections
TESTS_DIR ?= ./ansible_collections/ska_collections/k8s/tests

TAGS ?= all,metallb,cloudprovider,externaldns,ping,ingress,rookio,standardprovisioner,metrics,binderhub ## Ansible tags to run in post deployment processing
CAPI_CLUSTER ?= capo-test
K8S_KUBECONFIG ?= /etc/clusterapi/$(CAPI_CLUSTER)-kubeconfig

.DEFAULT_GOAL := help

vars:
	@echo "\033[36mclusterapi:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"
	@echo "ANSIBLE_PLAYBOOK_ARGUMENTS=$(ANSIBLE_PLAYBOOK_ARGUMENTS)"
	@echo "ANSIBLE_EXTRA_VARS=$(ANSIBLE_EXTRA_VARS)"
	@echo "ANSIBLE_SSH_ARGS=$(ANSIBLE_SSH_ARGS)"

k8s-get-kubeconfig:  ## Post deployment get workload kubeconfig
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/get-kubeconfig.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "capi_cluster=$(CAPI_CLUSTER)" \
	--limit "management-cluster" -vv

k8s-manual-deployment: ## Manual K8s deployment based on kubeadm

	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/k8s.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=workload-cluster" \
	--limit "workload-cluster" \
	--tags "$(TAGS)" \
	-vv

k8s-post-deployment:  ## Post deployment for workload cluster

#   echo "Controlplane initialise: cloud provider config"
#   echo "$OPENSTACK_CLOUD_PROVIDER_CONF_B64" | base64 -d > /etc/kubernetes/cloud.conf
#   cloud_provider_config: /etc/kubernetes/cloud.conf

ifneq (,$(findstring cloudprovider,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/cloudprovider.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "capi_cluster=$(CAPI_CLUSTER)" \
	--extra-vars "ingress_nginx_version=${NGINX_VERSION}" \
	--extra-vars "ingress_lb_suffix=${CLUSTER_NAME}" \
	--extra-vars "k8s_kubeconfig=$(K8S_KUBECONFIG)" \
	--tags "$(TAGS)" \
	-vv
endif

#	# --extra-vars 'ingress_nginx_version: 1.3.1 ingress_lb_suffix: "{{ capi_cluster }}"'
ifneq (,$(findstring ingress,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/ingress.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "k8s_kubeconfig=$(K8S_KUBECONFIG)" \
	--tags "$(TAGS)" \
	-vv
endif

ifneq (,$(findstring standardprovisioner,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/standardprovisioner.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "k8s_kubeconfig=$(K8S_KUBECONFIG)" \
	--tags "$(TAGS)" \
	-vv
endif

#	# --extra-vars 'metallb_version=0.13.7 metallb_namespace=metallb-system metallb_addresses="10.100.10.1-10.100.253.254"'
ifneq (,$(findstring metallb,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/metallb.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "k8s_kubeconfig=$(K8S_KUBECONFIG)" \
	--tags "$(TAGS)" \
	-vv
endif

ifneq (,$(findstring externaldns,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/externaldns.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "k8s_kubeconfig=$(K8S_KUBECONFIG)" \
	--tags "$(TAGS)" \
	-vv
endif

ifneq (,$(findstring ping,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/ping.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "k8s_kubeconfig=$(K8S_KUBECONFIG)" \
	--tags "$(TAGS)" \
	-vv
endif

ifneq (,$(findstring metrics,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/metrics.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "k8s_kubeconfig=$(K8S_KUBECONFIG)" \
	--tags "$(TAGS)" \
	-vv
endif

#	# ANSIBLE_EXTRA_VARS+= --extra-vars 'capi_ceph_conf_ini_file=<path to>/ceph.conf capi_ceph_conf_key_ring=<path to>/ceph.client.admin.keyring'
ifneq (,$(findstring rookio,$(TAGS)))
    # rookio is a target - avoid undefined ansible vars issue with tags
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/rookio.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "k8s_kubeconfig=$(K8S_KUBECONFIG)" \
	--tags "$(TAGS)" \
	-vv
endif

ifneq (,$(findstring binderhub,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/binderhub.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "k8s_kubeconfig=$(K8S_KUBECONFIG)" \
	--extra-vars k8s_binderhub_oci_registry_password=$(BINDERHUB_OCI_REGISTRY_PASSWORD) \
	--extra-vars k8s_binderhub_azuread_client_id=$(AZUREAD_CLIENT_ID) \
	--extra-vars k8s_binderhub_azuread_client_secret=$(AZUREAD_CLIENT_SECRET) \
	--extra-vars k8s_binderhub_azuread_tenant_id=$(AZUREAD_TENANT_ID) \
	--tags "$(TAGS)" \
	-vv
endif


k8s-velero-backups:  ## Configure Velero backups on Kubernetes
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/velero_backups.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "k8s_kubeconfig=$(K8S_KUBECONFIG)" \
	--extra-vars "cloud_config=$(K8S_CLOUD_CONFIG)"

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

k8s-post-deployment-test:
ifneq (,$(findstring ingress,$(TAGS)))
	@ansible-playbook $(TESTS_DIR)/test-ingress.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"
endif

ifneq (,$(findstring metrics,$(TAGS)))
	@ansible-playbook $(TESTS_DIR)/test-metrics.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"
endif

ifneq (,$(findstring standardprovisioner,$(TAGS)))
	@ansible-playbook $(TESTS_DIR)/test-storageprovisioner.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"
endif


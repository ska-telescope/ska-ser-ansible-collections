-include $(BASE_PATH)/PrivateRules.mak

k8s-check-hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

ANSIBLE_PLAYBOOK_ARGUMENTS ?=
ANSIBLE_EXTRA_VARS ?=
PLAYBOOKS_DIR ?= ./ansible_collections/ska_collections

TAGS ?= all,metallb,ingress,rookio,standardprovisioner,metallb ## Ansible tags to run in post deployment processing

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
	--limit "management-cluster" -vv

k8s-manual-deployment: ## Manual K8s deployment based on kubeadm

	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/k8s.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=workload-cluster" \
	--limit "workload-cluster" \
	--tags "$(TAGS)" \
	-vv

k8s-post-deployment:  ## Post deployment for workload cluster

ifneq (,$(findstring standardprovisioner,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/standardprovisioner.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=kubernetes-controlplane" \
	--limit "kubernetes-controlplane" \
	--tags "$(TAGS)" \
	-vv
endif

#	# --extra-vars 'metallb_version=0.13.7 metallb_namespace=metallb-system metallb_addresses="10.100.10.1-10.100.253.254"'
ifneq (,$(findstring metallb,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/metallb.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=kubernetes-controlplane" \
	--limit "kubernetes-controlplane" \
	--tags "$(TAGS)" \
	-vv
endif

#	# --extra-vars 'ingress_nginx_version: 1.3.1 ingress_lb_suffix: "{{ capi_cluster }}"'
ifneq (,$(findstring ingress,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/ingress.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=kubernetes-controlplane" \
	--limit "kubernetes-controlplane" \
	--tags "$(TAGS)" \
	-vv
endif

#	# ANSIBLE_EXTRA_VARS+= --extra-vars 'capi_ceph_conf_ini_file=<path to>/ceph.conf capi_ceph_conf_key_ring=<path to>/ceph.client.admin.keyring'
ifneq (,$(findstring rookio,$(TAGS)))
    # rookio is a target - avoid undefined ansible vars issue with tags
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/rookio.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=kubernetes-controlplane" \
	--limit "kubernetes-controlplane" \
	--tags "$(TAGS)" \
	-vv
endif

k8s-byoh-reset:  ## Reset workload hosts
	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="$(ANSIBLE_SSH_ARGS)" \
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/reset-byoh.yml \
	-i $(INVENTORY) --limit workload-cluster $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=workload-cluster" -v

k8s-byoh-init:  ## Initialise byoh workload hosts
	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="$(ANSIBLE_SSH_ARGS)" \
	ansible-playbook $(PLAYBOOKS_DIR)/clusterapi/playbooks/init-hosts.yml \
	-i $(INVENTORY) --limit workload-cluster $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=workload-cluster" -v

k8s-byoh-engine:  ## Deploy byoh container engine on workload hosts
	ANSIBLE_CONFIG="$(PLAYBOOKS_ROOT_DIR)/ansible.cfg" \
	ANSIBLE_SSH_ARGS="$(ANSIBLE_SSH_ARGS)" \
	ansible-playbook $(PLAYBOOKS_DIR)/docker_base/playbooks/containers.yml \
	-i $(INVENTORY) --limit workload-cluster $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=workload-cluster" -v

k8s-byoh:  ## Reset and prepare byoh nodes
	echo $(shell pwd)
	make -f k8s.mk k8s-byoh-reset
	make -f k8s.mk k8s-byoh-init
	make -f k8s.mk k8s-byoh-engine
	make -f k8s.mk k8s-byoh-agent


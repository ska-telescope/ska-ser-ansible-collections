.PHONY: check-hosts vars manual-deployment install test velero-backups-install help
.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
ANSIBLE_EXTRA_VARS ?=
PLAYBOOKS_DIR ?= ./ansible_collections/ska_collections
ANSIBLE_COLLECTIONS_PATHS ?=
TESTS_DIR ?= ./ansible_collections/ska_collections/k8s/tests

TAGS ?= all,metallb,externaldns,ping,ingress,rookio,standardprovisioner,metrics,binderhub,nvidia,vault,ska_tango_operator,coder,releases_notifier ## Ansible tags to run in post deployment processing

-include $(BASE_PATH)/PrivateRules.mak

check-hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

vars:
	@echo "\033[36mclusterapi:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"
	@echo "ANSIBLE_PLAYBOOK_ARGUMENTS=$(ANSIBLE_PLAYBOOK_ARGUMENTS)"
	@echo "ANSIBLE_EXTRA_VARS=$(ANSIBLE_EXTRA_VARS)"
	@echo "ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS)"
	@echo "ANSIBLE_SSH_ARGS=$(ANSIBLE_SSH_ARGS)"

manual-deployment: check-hosts  ## Manual K8s deployment based on kubeadm
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/k8s.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"

deploy-minikube:  ## Deploy Minikube single node cluster
	ansible-playbook $(PLAYBOOKS_DIR)/minikube/playbooks/minikube.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"

deploy-singlenode:  ## Deploy singlenode single node cluster
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/singlenode.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"

install-base:  ## Install container base for Kubernetes servers
	ansible-playbook $(PLAYBOOKS_DIR)/docker_base/playbooks/containers.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"

device-integration:  ## Deployment device integration to k8s cluster
	ANSIBLE_COLLECTIONS_PATHS=$(ANSIBLE_COLLECTIONS_PATHS) \
	ANSIBLE_ROLES_PATH=$(ANSIBLE_COLLECTIONS_PATHS) \
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/devices.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars "mlnx_ofed_version=5.9-0.5.6.0" \
	--extra-vars "mlnx_ofed_distro=ubuntu22.04" \
	--tags "$(TAGS)" \
	--flush-cache

destroy:

ifneq (,$(findstring vault,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/vault_destroy.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif

ifneq (,$(findstring binderhub,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/binderhub_destroy.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif

ifneq (,$(findstring coder,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/coder_destroy.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif

ifneq (,$(findstring eda,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/eda_destroy.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif


install: check-hosts  ## Post installations for a kubernetes cluster

ifneq (,$(findstring labels,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/node_labels.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif

ifneq (,$(findstring taints,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/node_taints.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif

ifneq (,$(findstring cloudprovider,$(TAGS))) # If you want to run the CCM install you must explicitly add 'cloudprovider' to TAGS
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/cloudprovider.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif

ifneq (,$(findstring ingress,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/ingress.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif

ifneq (,$(findstring standardprovisioner,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/standardprovisioner.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif

ifneq (,$(findstring metallb,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/metallb.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif

ifneq (,$(findstring externaldns,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/externaldns.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)" -vv
endif

ifneq (,$(findstring ping,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/ping.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif

ifneq (,$(findstring metrics,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/metrics.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif

ifneq (,$(findstring rookio,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/rookio.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif

ifneq (,$(findstring binderhub,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/binderhub.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif

ifneq (,$(findstring nvidia,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/nvidia.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif

ifneq (,$(findstring taranta,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/taranta.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif

ifneq (,$(findstring eda,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/eda.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif


ifneq (,$(findstring vault,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/vault.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)" \
	-vv
endif

ifneq (,$(findstring multihoming,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/multihoming.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif

ifneq (,$(findstring spookd_device_plugin,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/spookd_device_plugin.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif

ifneq (,$(findstring generic_device_plugin,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/generic_device_plugin.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif

ifneq (,$(findstring localpvs,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/localpvs.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif

ifneq (,$(findstring ska_tango_operator,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/ska_tango_operator.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)" \
	-vv
endif

ifneq (,$(findstring coder,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/coder.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif

ifneq (,$(findstring releases_notifier,$(TAGS)))
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/releases_notifier.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"
endif

test: check-hosts  # Test service deployments

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

ifneq (,$(findstring metallb,$(TAGS)))
	@ansible-playbook $(TESTS_DIR)/test-metallb.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"
endif

ifneq (,$(findstring nvidia,$(TAGS)))
	@ansible-playbook $(TESTS_DIR)/test-nvidia.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"
endif

ifneq (,$(findstring ping,$(TAGS)))
	@ansible-playbook $(TESTS_DIR)/test-ping.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"
endif

ifneq (,$(findstring vault,$(TAGS)))
	@ansible-playbook $(TESTS_DIR)/test-vault.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"
endif

ifneq (,$(findstring rookio,$(TAGS)))
	@ansible-playbook $(TESTS_DIR)/test-rookio.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"
endif

ifneq (,$(findstring ska_tango_operator,$(TAGS)))
	@ansible-playbook $(TESTS_DIR)/test-ska-tango-operator.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"
endif

velero-backups-install: check-hosts  ## Configure Velero backups on Kubernetes. Check the role README.md for how to operate with velero
	ansible-playbook $(PLAYBOOKS_DIR)/k8s/playbooks/velero_backups.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--tags "$(TAGS)"

help:  ## Show Help
	@echo "K8s targets - make playbooks k8s <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

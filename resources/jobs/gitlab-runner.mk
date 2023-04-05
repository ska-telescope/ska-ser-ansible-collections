.PHONY: check_hosts check_gitlab_runner_secrets vars install destroy help
.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
ANSIBLE_EXTRA_VARS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)
PLAYBOOKS_DIR ?= ./ansible_collections/ska_collections/gitlab_runner/playbooks

GITLAB_RUNNER_K8S_CLUSTER ?= localhost## subset of hosts from inventory to run against, default is set to localhost so that it works with local kubeconfig
GITLAB_RUNNER_STORAGE_CLASS ?= block ## Minio shared cache StorageClass
GITLAB_RUNNER_K8S_NAMESPACE ?= gitlab
GITLAB_RUNNER_K8S_RELEASE_NAME ?= gitlab-runner
GITLAB_RUNNER_MINIO_RELEASE ?= minio-cache
GITLAB_RUNNER_MINIO_BUCKET_NAME ?= cache
GITLAB_RUNNER_MINIO_BUCKET_LOCATION ?= 
GITLAB_RUNNER_GITLAB_VAULT_PREFIX ?= stfc
GITLAB_RUNNER_K8S_NODE_LABEL ?= node-role.skatelescope.org/ci-worker
GITLAB_RUNNER_TOKEN ?= xxx ## GitLab Registration Token
GITLAB_RUNNER_TAG_LIST ?= ## Runner tags, if this is defined these values are used, else the values defined in the group_vars directory are used
V ?= ## ansible-playbook debug options, i.e. -vvv
GITLAB_RUNNER_LOCAL_DOCKER ?= 127.0.0.1
GITLAB_RUNNER_METRICS_PORT ?= 30931

-include $(BASE_PATH)/PrivateRules.mak

ifneq ($(GITLAB_RUNNER_TAG_LIST),)
GITLAB_RUNNER_TAG_LIST_ARG = -e 'gitlab_tag_list="${GITLAB_RUNNER_TAG_LIST}"'
else
endif

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

vars:
	@echo "\033[36mGitlab_runner:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"
	@echo "GITLAB_RUNNER_K8S_NAMESPACE=$(GITLAB_RUNNER_K8S_NAMESPACE)"
	@echo "GITLAB_RUNNER_K8S_RELEASE_NAME=$(GITLAB_RUNNER_K8S_RELEASE_NAME)"
	@echo "GITLAB_RUNNER_MINIO_RELEASE=$(GITLAB_RUNNER_MINIO_RELEASE)"
	@echo "GITLAB_RUNNER_K8S_RELEASE_NAME=$(GITLAB_RUNNER_K8S_RELEASE_NAME)"
	@echo "GITLAB_RUNNER_K8S_NODE_LABEL=$(GITLAB_RUNNER_K8S_NODE_LABEL)"
	@echo "GITLAB_RUNNER_K8S_CLUSTER=$(GITLAB_RUNNER_K8S_CLUSTER)"
	@echo "GITLAB_RUNNER_TAG_LIST=$(GITLAB_RUNNER_TAG_LIST)"

install_runner_docker_executor: check_hosts ## Deploy gitlab_runner
	ansible-playbook $(PLAYBOOKS_DIR)/install_runner_docker_executor.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

destroy_runner_docker_executor: check_hosts ## Destroy gitlab_runner
	ansible-playbook $(PLAYBOOKS_DIR)/destroy_runner_docker_executor.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

envsubst:
	@GITLAB_RUNNER_K8S_RELEASE_NAME=$(GITLAB_RUNNER_K8S_RELEASE_NAME) \
	 GITLAB_RUNNER_METRICS_PORT=$(GITLAB_RUNNER_METRICS_PORT) \
	 envsubst < $(PLAYBOOKS_DIR)/../roles/k8s/files/runner-metrics.yaml.in >$(PLAYBOOKS_DIR)/../roles/k8s/files/runner-metrics.yaml

tidy:  ## Clean up patch files
	@rm -rf ./runner_kustomize/cache-secret.yaml \
	./playbooks/files/minio_tenant.yml

label_nodes:  ## Label worker nodes for CI
	ansible-playbook $(PLAYBOOKS_DIR)/label_nodes.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	$(GITLAB_RUNNER_TAG_LIST_ARG) \
	  --extra-vars="gitlab_runner_k8s_namespace=$(GITLAB_RUNNER_K8S_NAMESPACE)" \
	  --extra-vars="gitlab_runner_k8s_release_name='$(GITLAB_RUNNER_K8S_RELEASE_NAME)'" \
	  --extra-vars="gitlab_runner_k8s_node_label='$(GITLAB_RUNNER_K8S_NODE_LABEL)'" \
	  $(V)

k8s_runner: tidy envsubst  ## Deploy runners
	ansible-playbook $(PLAYBOOKS_DIR)/generate_manifest_runner.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	$(GITLAB_RUNNER_TAG_LIST_ARG) \
	-e "gitlab_runner_k8s_namespace=$(GITLAB_RUNNER_K8S_NAMESPACE)" \
	-e "gitlab_runner_k8s_release_name='$(GITLAB_RUNNER_K8S_RELEASE_NAME)'" \
	-e "gitlab_runner_k8s_node_label='$(GITLAB_RUNNER_K8S_NODE_LABEL)'" \
	-e "gitlab_runner_k8s_s3_bucket_name=$(GITLAB_RUNNER_MINIO_BUCKET_NAME)" \
	-e "gitlab_runner_k8s_s3_bucket_location=$(GITLAB_RUNNER_MINIO_BUCKET_LOCATION)" \
	-e "gitlab_vault_prefix=$(GITLAB_RUNNER_GITLAB_VAULT_PREFIX)" \
	$(V)

deploy_minio: tidy envsubst  ## Deploy Minio
	ansible-playbook $(PLAYBOOKS_DIR)/deploy_minio.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	$(GITLAB_RUNNER_TAG_LIST_ARG) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars="gitlab_runner_minio_namespace=$(GITLAB_RUNNER_K8S_NAMESPACE) minio_release_name='$(GITLAB_RUNNER_MINIO_RELEASE)'" \
	--extra-vars="gitlab_runner_minio_storage_class=$(GITLAB_RUNNER_STORAGE_CLASS)" \
	--extra-vars="gitlab_runner_gitlab_s3_bucket_name=$(GITLAB_RUNNER_MINIO_BUCKET_NAME)" \
	$(V)

# ANSIBLE_STDOUT_CALLBACK=yaml makes it nice to read
show_minio: tidy envsubst  ## Show Mino chart
	ANSIBLE_STDOUT_CALLBACK=yaml ansible-playbook $(PLAYBOOKS_DIR)/show_minio.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars="gitlab_runner_minio_namespace=$(GITLAB_RUNNER_K8S_NAMESPACE) minio_release_name='$(GITLAB_RUNNER_MINIO_RELEASE)'" \
	--extra-vars="gitlab_runner_minio_storage_class=$(GITLAB_RUNNER_STORAGE_CLASS)" \
	--extra-vars="gitlab_runner_gitlab_s3_bucket_name=$(GITLAB_RUNNER_MINIO_BUCKET_NAME)" \
	$(V)

destroy_minio:  ## Delete minio
	ansible-playbook $(PLAYBOOKS_DIR)/destroy_minio.yml \
	-i $(INVENTORY) $(ANSIBLE_PLAYBOOK_ARGUMENTS) $(ANSIBLE_EXTRA_VARS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)" \
	--extra-vars="gitlab_runner_gitlab_s3_bucket_name=$(GITLAB_RUNNER_MINIO_BUCKET_NAME)" \
	$(V)

runner_logs: ## Show runner logs
	@for i in `kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) get pods -l release=$(GITLAB_RUNNER_K8S_RELEASE_NAME) -o=name`; \
	do \
	echo "---------------------------------------------------"; \
	echo "Logs for $${i}"; \
	echo kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) logs $${i}; \
	echo kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) get $${i} -o jsonpath="{.spec.initContainers[*].name}"; \
	echo "---------------------------------------------------"; \
	for j in `kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) get $${i} -o jsonpath="{.spec.initContainers[*].name}"`; do \
	RES=`kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) logs $${i} -c $${j} 2>/dev/null`; \
	echo "initContainer: $${j}"; echo "$${RES}"; \
	echo "---------------------------------------------------";\
	done; \
	echo "Main Pod logs for $${i}"; \
	echo "---------------------------------------------------"; \
	for j in `kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) get $${i} -o jsonpath="{.spec.containers[*].name}"`; do \
	RES=`kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) logs $${i} -c $${j} 2>/dev/null`; \
	echo "Container: $${j}"; echo "$${RES}"; \
	echo "---------------------------------------------------";\
	echo "config.toml for: $${j}"; \
	rm -f /tmp/config.toml; \
	kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) cp $$(echo "$${i}" | cut -d/ -f 2):/home/gitlab-runner/.gitlab-runner /tmp/; \
	echo "---------------------------------------------------";\
	cat /tmp/config.toml; \
	done; \
	done

minio_logs: ## Show minio logs
	@for i in `kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) get pods -l app=minio -o=name`; \
	do \
	echo "---------------------------------------------------"; \
	echo "Logs for $${i}"; \
	echo kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) logs $${i}; \
	echo kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) get $${i} -o jsonpath="{.spec.initContainers[*].name}"; \
	echo "---------------------------------------------------"; \
	for j in `kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) get $${i} -o jsonpath="{.spec.initContainers[*].name}"`; do \
	RES=`kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) logs $${i} -c $${j} 2>/dev/null`; \
	echo "initContainer: $${j}"; echo "$${RES}"; \
	echo "---------------------------------------------------";\
	done; \
	echo "Main Pod logs for $${i}"; \
	echo "---------------------------------------------------"; \
	for j in `kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) get $${i} -o jsonpath="{.spec.containers[*].name}"`; do \
	RES=`kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) logs $${i} -c $${j} 2>/dev/null`; \
	echo "Container: $${j}"; echo "$${RES}"; \
	echo "---------------------------------------------------";\
	done; \
	done

list_cache:  ## list the minio cache using in-cluster connection
	@kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) run mc --rm -ti --image=minio/mc --restart=Never --command -- \
	/bin/sh -c "mc alias set cache http://minio $(ACCESS_KEY) $(SECRET_KEY); mc ls --recursive cache/"

list_cache_remote: ## list the global minio cache using remote connection
	docker run --rm -it --entrypoint=/bin/sh minio/mc -c 'mc alias set cache https://k8s.stfc.skao.int:9443 $(ACCESS_KEY) $(SECRET_KEY); mc ls --recursive cache/'

get_cache:  ## retrieve the minio cache
	sudo rm -rf $$(pwd)/tmp
	mkdir -p $$(pwd)/tmp
	kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) port-forward service/minio 9001:80 &
	sleep 3
	docker run --rm -it --net=host \
	-e HOME=$${HOME} \
	-v /etc/passwd:/etc/passwd:ro --user=$$(id -u) \
	-v $${HOME}:$${HOME} -w $${HOME} \
	--volume $$(pwd)/tmp:/mnt \
	--entrypoint=/bin/sh minio/mc -c \
	'mc alias set cache http://$(GITLAB_RUNNER_LOCAL_DOCKER):9001 $(ACCESS_KEY) $(SECRET_KEY); mc ls --recursive cache; mc cp --recursive cache/cache /mnt/'
	ls -lR $$(pwd)/tmp
	ps axf | grep 'port-forward service' | grep -v grep | awk '{print $$1}' | xargs kill

get_key: ## get keys from minio environmen variables
	kubectl exec -n gitlab -it minio-ss-0-0 -- env | grep KEY

get_operator_jwt: ## get jwt token for operator console
	kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) get secret $$(kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) get serviceaccount console-sa -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode

forward_operator_console: ## port forward operator console on 9090
	kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) port-forward svc/console 9090:9090

forward_tenant_console: ## port forward tenant console on 9091
	kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) port-forward svc/minio-console 9091:9090

# https://docs.min.io/minio/baremetal/reference/minio-cli/minio-mc/mc-rm.html#mc-rm-older-than
prune_cache:  ## prune the minio cache
	@kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) run mc --rm -ti --image=minio/mc --restart=Never --command -- \
	/bin/sh -c "mc alias set cache http://minio $(ACCESS_KEY) $(SECRET_KEY); mc rm --older-than 15d --recursive --dangerous --force cache/"

delete_ilm:
	@kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) run mc --rm -ti --image=minio/mc --restart=Never --command -- \
	/bin/sh -c "mc alias set cache http://minio $(ACCESS_KEY) $(SECRET_KEY); mc ilm rule rm --id $(MINIO_ILM_LIFECYCLE_ID) cache/cache"

add_ilm:
	@kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) run mc --rm -ti --image=minio/mc --restart=Never --command -- \
	/bin/sh -c "mc alias set cache http://minio $(ACCESS_KEY) $(SECRET_KEY); mc ilm rule add --expire-days 30 cache/cache"

list_ilms:
	@kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) run mc --rm -ti --image=minio/mc --restart=Never --command -- \
	/bin/sh -c "mc alias set cache http://minio $(ACCESS_KEY) $(SECRET_KEY); mc ilm rule ls cache/cache"

create_cache_bucket: ## create the minio bucket named cache for gitlab manually
	@kubectl -n $(GITLAB_RUNNER_K8S_NAMESPACE) run mc --rm -ti --image=minio/mc --restart=Never --command -- \
	/bin/sh -c "mc alias set cache http://minio $(ACCESS_KEY) $(SECRET_KEY); mc mb --ignore-existing cache/$(MINIO_BUCKET_NAME)"

help: ## Show Help
	@echo "Gitlab_runner targets - make playbooks gitlab_runner <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

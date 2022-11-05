.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=
INVENTORY ?= $(PLAYBOOKS_ROOT_DIR)

-include $(BASE_PATH)/PrivateRules.mak

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

check_elastic_secrets:
ifndef CA_CERT_PASSWORD
	$(error CA_CERT_PASSWORD is undefined)
endif
ifndef ELASTICSEARCH_PASSWORD
	$(error ELASTICSEARCH_PASSWORD is undefined)
endif
ifndef ELASTIC_HAPROXY_STATS_PASSWORD
	$(error ELASTIC_HAPROXY_STATS_PASSWORD is undefined)
endif
ifndef KIBANA_VIEWER_PASSWORD
	$(error KIBANA_VIEWER_PASSWORD is undefined)
endif

# You can set these variables from the command line.
ELASTIC_USER ?= elastic
LOGGING_URL ?= https://logging.stfc.skao.int:9200
LOADBALANCER_IP ?= logging.stfc.skao.int
CA_CERT ?= /etc/pki/tls/private/ca-certificate.crt
CERT ?= /etc/pki/tls/private/ska-techops-logging-central-prod-loadbalancer.crt
CERT_KEY ?= /etc/pki/tls/private/ska-techops-logging-central-prod-loadbalancer.key
PEM_FILE ?= ~/.ssh/ska-techops.pem

vars:
	@echo "\033[36mLogging:\033[0m"
	@echo "INVENTORY=$(INVENTORY)"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"
	@echo "CA_CERT_PASSWORD=$(CA_CERT_PASSWORD)"
	@echo "ELASTICSEARCH_PASSWORD=$(ELASTICSEARCH_PASSWORD)"
	@echo "ELASTIC_HAPROXY_STATS_PASSWORD=$(ELASTIC_HAPROXY_STATS_PASSWORD)"
	@echo "KIBANA_VIEWER_PASSWORD=$(KIBANA_VIEWER_PASSWORD)"

install: check_hosts check_elastic_secrets ## Install elastic
	ansible-playbook ./ansible_collections/ska_collections/logging/playbooks/install.yml \
	-i $(INVENTORY) \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
	--extra-vars " \
		target_hosts=$(PLAYBOOKS_HOSTS) \
		ca_cert_password=$(CA_CERT_PASSWORD) \
		elasticsearch_password=$(ELASTICSEARCH_PASSWORD) \
		elastic_haproxy_stats_passwd=$(ELASTIC_HAPROXY_STATS_PASSWORD) \
		kibana_viewer_password=$(KIBANA_VIEWER_PASSWORD) \
	"

destroy: check_hosts ## Destroy elastic cluster
	ansible-playbook ./ansible_collections/ska_collections/logging/playbooks/destroy.yml \
	-i $(INVENTORY) \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

install-beats: check_hosts check_logging_secrets ## Install logging
	ansible-playbook ./ansible_collections/ska_collections/logging/playbooks/logging.yml \
	-i $(INVENTORY) \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
	--extra-vars " \
		target_hosts=$(PLAYBOOKS_HOSTS) \
		ca_cert_password=$(CA_CERT_PASSWORD) \
		elasticsearch_password=$(ELASTICSEARCH_PASSWORD) \
	"

## API targets
check: ## Check Elastic API status
	@ssh -qt -i $(PEM_FILE) ubuntu@$(LOADBALANCER_IP) \
		"sudo curl -X GET -u $(ELASTIC_USER):$(ELASTIC_PASSWORD) --cacert $(CA_CERT) --cert $(CERT) --key $(CERT_KEY) '$(LOGGING_URL)/_cat/health?pretty'"

key-list: ## List existing Elastic API keys
	@echo "Existing API keys:"
	@echo ""
	@ssh -qt -i $(PEM_FILE) ubuntu@$(LOADBALANCER_IP) \
		"sudo curl -X GET -u $(ELASTIC_USER):$(ELASTIC_PASSWORD) --cacert $(CA_CERT) --cert $(CERT) --key $(CERT_KEY) '$(LOGGING_URL)/_security/api_key?pretty'"

ifdef KEY_NAME
ifdef KEY_EXPIRATION
key-new: ## Create new key. Pass name of the key as KEY_NAME=xxx. Pass optional expiration as KEY_EXPIRATION=xxx.
	@echo "Create API key with expiration date:"
	@echo ""
	@ssh -qt -i $(PEM_FILE) ubuntu@$(LOADBALANCER_IP) \
		"sudo curl -X POST -u $(ELASTIC_USER):$(ELASTIC_PASSWORD) --cacert $(CA_CERT) --cert $(CERT) --key $(CERT_KEY) '$(LOGGING_URL)/_security/api_key?pretty' -H 'Content-Type: application/json' -d'{\"name\": \"$(KEY_NAME)\", \"expiration\": \"$(KEY_EXPIRATION)\"}'"
else
key-new:
	@echo "Create API key without expiration date:"
	@echo ""
	@ssh -qt -i $(PEM_FILE) ubuntu@$(LOADBALANCER_IP) \
		"sudo curl -X POST -u $(ELASTIC_USER):$(ELASTIC_PASSWORD) --cacert $(CA_CERT) --cert $(CERT) --key $(CERT_KEY) '$(LOGGING_URL)/_security/api_key?pretty' -H 'Content-Type: application/json' -d'{\"name\": \"$(KEY_NAME)\"}'"
endif
else
key-new:
	@echo "ERROR: Please pass name of the key as KEY_NAME=xxx"
	@exit 1
endif

ifdef KEY_ID
key-info: ## Get API key info. Pass the id of the key as KEY_ID=xxx
	@echo "Information on API key: $(KEY_ID)"
	@echo ""
	@ssh -qt -i $(PEM_FILE) ubuntu@$(LOADBALANCER_IP) \
		"sudo curl -X GET -u $(ELASTIC_USER):$(ELASTIC_PASSWORD) --cacert $(CA_CERT) --cert $(CERT) --key $(CERT_KEY) '$(LOGGING_URL)/_security/api_key?id=$(KEY_ID)&pretty'"
else
key-info:
	@echo "ERROR: Please pass id of the key as KEY_ID=xxx"
	@exit 1
endif

ifdef KEY_ID
key-invalidate: ## Invalidate API key. Pass the id of the key as KEY_ID=xxx
	@echo "Delete API key: $(KEY_ID)"
	@echo ""
	@ssh -qt -i $(PEM_FILE) ubuntu@$(LOADBALANCER_IP) \
		"sudo curl -X DELETE -u $(ELASTIC_USER):$(ELASTIC_PASSWORD) --cacert $(CA_CERT) --cert $(CERT) --key $(CERT_KEY) '$(LOGGING_URL)/_security/api_key?pretty' -H 'Content-Type: application/json' -d'{\"ids\": \"$(KEY_ID)\"}'"
else
key-invalidate:
	@echo "ERROR: Please pass id of the key as KEY_ID=xxx"
	@exit 1
endif

ifdef KEY
key-query: ## Query health using API key. Pass the encoded API Key as KEY=xxx
	@echo "Query cluster health using encoded API key: $(KEY)"
	@echo ""
	@ssh -qt -i $(PEM_FILE) ubuntu@$(LOADBALANCER_IP) \
		"sudo curl -X GET --cacert $(CA_CERT) --cert $(CERT) --key $(CERT_KEY) '$(LOGGING_URL)/_cat/health?pretty' -H 'authorization: ApiKey $(KEY)'"
else
key-query:
	@echo "ERROR: Please pass encoded API key as KEY=xxx"
	@exit 1
endif

help: ## Show Help
	@echo "Elastic targets - make playbooks elastic <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
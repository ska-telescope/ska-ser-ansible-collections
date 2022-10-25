.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK_ARGUMENTS ?=

-include $(BASE_PATH)/PrivateRules.mak

check_hosts:
ifndef PLAYBOOKS_HOSTS
	$(error PLAYBOOKS_HOSTS is undefined)
endif

check_secrets:
ifndef CA_CERT_PASS
	$(error CA_CERT_PASS is undefined)
endif
ifndef ELASTICSEARCH_PASSWORD
	$(error ELASTICSEARCH_PASSWORD is undefined)
endif
ifndef ELASTIC_HAPROXY_STATS_PASSWORD
	$(error ELASTIC_HAPROXY_STATS_PASSWORD is undefined)
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
	@echo "\033[36mElasticsearch:\033[0m"
	@echo "PLAYBOOKS_HOSTS=$(PLAYBOOKS_HOSTS)"
	@echo "CA_CERT_PASS=$(CA_CERT_PASS)"
	@echo "ELASTICSEARCH_PASSWORD=$(ELASTICSEARCH_PASSWORD)"
	@echo "ELASTIC_HAPROXY_STATS_PASSWORD=$(ELASTIC_HAPROXY_STATS_PASSWORD)"

install: check_hosts check_secrets ## Install elastic
	ansible-playbook ./ansible_collections/ska_collections/elastic/playbooks/install.yml \
	-i $(PLAYBOOKS_ROOT_DIR) \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
	--extra-vars " \
		target_hosts=$(PLAYBOOKS_HOSTS) \
		ca_cert_pass=$(CA_CERT_PASS) \
		elasticsearch_password=$(ELASTICSEARCH_PASSWORD) \
		elastic_haproxy_stats_passwd=$(ELASTIC_HAPROXY_STATS_PASSWORD) \
		kibana_viewer_password=$(KIBANA_VIEWER_PASSWORD) \
	"

destroy: check_hosts ## Destroy elastic cluster
	ansible-playbook ./ansible_collections/ska_collections/elastic/playbooks/destroy.yml \
	-i $(PLAYBOOKS_ROOT_DIR) \
	$(ANSIBLE_PLAYBOOK_ARGUMENTS) \
	--extra-vars "target_hosts=$(PLAYBOOKS_HOSTS)"

help: ## Show Help
	@echo "ElasticSearch targets - make playbooks elastic <target>:"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": .*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

## API targets
elastic-check: ## Check Elastic API status
	@ssh -qt -i $(PEM_FILE) ubuntu@$(LOADBALANCER_IP) \
		"sudo curl -X GET -u $(ELASTIC_USER):$(ELASTIC_PASSWORD) --cacert $(CA_CERT) --cert $(CERT) --key $(CERT_KEY) '$(LOGGING_URL)/_cat/health?pretty'"

elastic-key-list: ## List existing Elastic API keys
	@echo "Existing API keys:"
	@echo ""
	@ssh -qt -i $(PEM_FILE) ubuntu@$(LOADBALANCER_IP) \
		"sudo curl -X GET -u $(ELASTIC_USER):$(ELASTIC_PASSWORD) --cacert $(CA_CERT) --cert $(CERT) --key $(CERT_KEY) '$(LOGGING_URL)/_security/api_key?pretty'"

ifdef KEY_NAME
ifdef KEY_EXPIRATION
elastic-key-new: ## Create new key. Pass name of the key as KEY_NAME=xxx. Pass optional expiration as KEY_EXPIRATION=xxx.
	@echo "Create API key with expiration date:"
	@echo ""
	@ssh -qt -i $(PEM_FILE) ubuntu@$(LOADBALANCER_IP) \
		"sudo curl -X POST -u $(ELASTIC_USER):$(ELASTIC_PASSWORD) --cacert $(CA_CERT) --cert $(CERT) --key $(CERT_KEY) '$(LOGGING_URL)/_security/api_key?pretty' -H 'Content-Type: application/json' -d'{\"name\": \"$(KEY_NAME)\", \"expiration\": \"$(KEY_EXPIRATION)\"}'"
else
elastic-key-new:
	@echo "Create API key without expiration date:"
	@echo ""
	@ssh -qt -i $(PEM_FILE) ubuntu@$(LOADBALANCER_IP) \
		"sudo curl -X POST -u $(ELASTIC_USER):$(ELASTIC_PASSWORD) --cacert $(CA_CERT) --cert $(CERT) --key $(CERT_KEY) '$(LOGGING_URL)/_security/api_key?pretty' -H 'Content-Type: application/json' -d'{\"name\": \"$(KEY_NAME)\"}'"
endif
else
elastic-key-new:
	@echo "ERROR: Please pass name of the key as KEY_NAME=xxx"
	@exit 1
endif

ifdef KEY_ID
elastic-key-info: ## Get API key info. Pass the id of the key as KEY_ID=xxx
	@echo "Information on API key: $(KEY_ID)"
	@echo ""
	@ssh -qt -i $(PEM_FILE) ubuntu@$(LOADBALANCER_IP) \
		"sudo curl -X GET -u $(ELASTIC_USER):$(ELASTIC_PASSWORD) --cacert $(CA_CERT) --cert $(CERT) --key $(CERT_KEY) '$(LOGGING_URL)/_security/api_key?id=$(KEY_ID)&pretty'"
else
elastic-key-info:
	@echo "ERROR: Please pass id of the key as KEY_ID=xxx"
	@exit 1
endif

ifdef KEY_ID
elastic-key-invalidate: ## Invalidate API key. Pass the id of the key as KEY_ID=xxx
	@echo "Delete API key: $(KEY_ID)"
	@echo ""
	@ssh -qt -i $(PEM_FILE) ubuntu@$(LOADBALANCER_IP) \
		"sudo curl -X DELETE -u $(ELASTIC_USER):$(ELASTIC_PASSWORD) --cacert $(CA_CERT) --cert $(CERT) --key $(CERT_KEY) '$(LOGGING_URL)/_security/api_key?pretty' -H 'Content-Type: application/json' -d'{\"ids\": \"$(KEY_ID)\"}'"
else
elastic-key-invalidate:
	@echo "ERROR: Please pass id of the key as KEY_ID=xxx"
	@exit 1
endif

ifdef KEY
elastic-key-query: ## Query health using API key. Pass the encoded API Key as KEY=xxx
	@echo "Query cluster health using encoded API key:"
	@echo ""
	@ssh -qt -i $(PEM_FILE) ubuntu@$(LOADBALANCER_IP) \
		"sudo curl -X GET --cacert $(CA_CERT) --cert $(CERT) --key $(CERT_KEY) '$(LOGGING_URL)/_cat/health?pretty' -H 'authorization: ApiKey $(KEY)'"
else
elastic-key-query:
	@echo "ERROR: Please pass encoded API key as KEY=xxx"
	@exit 1
endif

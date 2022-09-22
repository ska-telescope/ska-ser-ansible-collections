

ping:  ## Install elasticstack
	ansible elasticsearch -i ../environments/$(ENVIRONMENT)/installation/inventory.yml  -m ping
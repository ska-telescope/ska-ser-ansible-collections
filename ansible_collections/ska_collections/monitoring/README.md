# SKA Monitoring Collection

This collection includes a variety of Ansible roles to help automate the installation and configuration of the monitoring stack: [Prometheus](https://prometheus.io/) + [Thanos](https://thanos.io/) and [Grafana](https://grafana.com/).
This collection is currently maintained by [SKAO](https://www.skao.int/).

## Ansible

Tested with the current Ansible 6.5.x releases.

## Ansible Roles
| Name | Description | Version | OS Requirements | Dependencies |
| ---- | ----------- | ------- | --- | ---|
| [monitoring.custom_metrics](./roles/custom_metrics) | Adds custom metrics | | Ubuntu 18+ (LTS) | |
| [monitoring.node_exporter](./roles/node_exporter) | Install the node exporter | 1.4.0 | Ubuntu 18+ (LTS) | |
| [monitoring.prometheus](./roles/beats) | Installs Prometheus, Thanos and Grafana | Grafana: 17.2.5 <br> Thanos: 0.28.0 <br> Prometheus: 2.37.1| Ubuntu 18+ (LTS) | |

## Installation



Before using the collection, you need to install the collection with the `ansible-galaxy` CLI:

    ansible-galaxy collection install ska_collections.monitoring

You can also include it in a `requirements.yml` file and install it via ansible-galaxy collection install -r requirements.yml` using the format:

```yaml
collections:
- name: ska_collections.monitoring
```

## Usage

Playbooks can be found in the [playbooks/](./playbooks) folder in the following files:

| Name | Description |
| ---- | ----------- |
| [deploy_docker_exporter.yml](./playbooks/deploy_docker_exporter.yml) | Deploys docker exporter  |
| [deploy_monitoring.yml](./playbooks/deploy_monitoring.yml) | Installs Prometheus, Thanos and Grafana|
| [deploy_node_exporter.yml](./playbooks/deploy_node_exporter.yml) | Deploys node exporter|
| [export_runners.yml](./playbooks/export_runners.yml) | Export runners |

In order to run these playbooks, it's needed to specify the Ansible Inventory location and the respective group/hosts ***target_hosts*** variable.

Run **deploy_monitoring** playbook as an example:
```
ansible-playbook <playbooks-folder-path>/deploy_monitoring.yml \
	-i $(INVENTORY) \
	--extra-vars "target_hosts=<target-hosts>"
```


### Required variables

| Name | Ansible variable | ENV variable | Obs |
| ---- | ----------- | ----- | ----- |
| Deploy monitoring mode | mode | | *server* <br> *runner* <br> *grafana* <br> *alert* <br> *thanos* |
| Slack API User | slack_api_url_user | SLACK_API_URL_USER | |
| Azure AD Client ID | azuread_client_id | AZUREAD_CLIENT_ID | |
| Azure AD Tenant ID | azuread_tenant_id | AZUREAD_TENANT_ID | |
| Prometheus Project ID | project_id | PROM_OS_PROJECT_ID | |
| Prometheus Authentication Url | auth_url | PROM_OS_AUTH_URL | |
| Kubernetes Configuration File | kubeconfig | KUBECONFIG | |
| Prometheus username | username | PROM_OS_USERNAME | |


### Required secrets

| Name | Ansible variable | ENV variable | Obs |
| ---- | ----------- | ------------ | ----- |
| Slack API Webhook Url | slack_api_url | SLACK_API_URL | |
| Azure AD Client Token | azuread_client_secret | AZUREAD_CLIENT_SECRET | |
| Gitlab Pipeline Exporter Token | prometheus_gitlab_ci_pipelines_exporter_token | GITLAB_TOKEN | |
| Prometheus password | password | PROM_OS_PASSWORD | |
| Certificate Authority Password | ca_cert_password | CA_CERT_PASSWORD | |

## How to Contribute

### Adding a new role
A new role can be added to the [roles](./roles/) folder and then included into a new and/or existing playbook.

### Updating an existing role
The existing roles can be found in the [roles](./roles/) folder. To update a role, the role's tasks can be simply modified.

### External dependencies
Go to [requirements.yml](../../../requirements.yml) and [galaxy.yml](./galaxy.yml) files to add or update any external dependency.

### Add/Update new variables
Ansible variables that are datacentre specific should be added to the `group_vars` folder of the inventory.

To modify non-secret variable role defaults, go to the defaults folder of the respective role and update them. As an [example](./roles/prometheus/defaults/main.yml).

Finally, the secret variables are defined in the respective [Makefile](../../../resources/jobs/monitoring.mk) and can be modified there. To assign proper values to these variables, please use a `PrivateRules.mak` file.

## More information

- [Ansible Using collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html)
- [Ansible Collection overview](https://github.com/ansible-collections/overview)
- [Ansible User guide](https://docs.ansible.com/ansible/latest/user_guide/index.html)
- [Ansible Developer guide](https://docs.ansible.com/ansible/latest/dev_guide/index.html)
- [Ansible Community code of conduct](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html)

## License

BSD-3.
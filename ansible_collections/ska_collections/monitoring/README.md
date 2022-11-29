# SKA Monitoring Collection

This collection includes a variety of Ansible roles to help automate the installation and configuration of the monitoring stack: [Prometheus](https://prometheus.io/) + [Thanos](https://thanos.io/) and [Grafana](https://grafana.com/).
This collection is currently maintained by [SKAO](https://www.skao.int/).

## Ansible

Tested with the current Ansible 6.5.x releases.

## Ansible Roles
| Name | Description |
| ---- | ----------- |
| [monitoring.alertmanager](./roles/alertmanager) | Installs the [Alert Manager](https://prometheus.io/docs/alerting/latest/alertmanager/) |
| [monitoring.custom_metrics](.roles/custom_metrics) | Adds custom metrics exporter as cron job |
| [monitoring.grafana](.roles/grafana) | Install [Grafana](https://grafana.com/grafana/) |
| [monitoring.node_exporter](./roles/node_exporter) | Installs the [prometheus node exporter](https://github.com/prometheus/node_exporter) |
| [monitoring.prometheus](./roles/prometheus) | Installs [Prometheus](https://prometheus.io/) |
| [monitoring.thanos](./roles/thanos) | Installs [Thanos](https://thanos.io/) components |


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
| [deploy_alertmanager.yml](./playbooks/deploy_alertmanager.yml) | Deploys  [Alert Manager](https://prometheus.io/docs/alerting/latest/alertmanager/) |
| [deploy_grafana.yml](./playbooks/deploy_grafana.yml) | Installs [Grafana](https://grafana.com/grafana/) |
| [deploy_node_exporter.yml](./playbooks/deploy_node_exporter.yml) | Deploys [prometheus node exporter](https://github.com/prometheus/node_exporter) |
| [deploy_prometheus.yml](./playbooks/deploy_prometheus.yml) | Deploys [Prometheus](https://prometheus.io/) |
| [deploy_thanos.yml](./playbooks/deploy_thanos.yml) | Deploys [Thanos](https://thanos.io/) |


In order to run these playbooks, it's needed to specify the Ansible Inventory location and the respective group/hosts ***target_hosts*** variable.

Run **deploy_monitoring** playbook as an example:
```
ansible-playbook <playbooks-folder-path>/deploy_prometheus.yml \
	-i <inventory_file> \
	--extra-vars "target_hosts=<target-hosts>"
```

### Required variables

| Name | Ansible variable | ENV variable | Description |
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

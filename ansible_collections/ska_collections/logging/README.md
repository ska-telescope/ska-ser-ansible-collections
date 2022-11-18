# SKA Logging Collection

This collection includes a variety of Ansible roles to help automate the installation and configuration of [Elasticsearch Stack](https://www.elastic.co/elastic-stack/).
This collection is currently maintained by [SKAO](https://www.skao.int/).

## Ansible

Tested with the current Ansible 6.5.x releases.

## Ansible Roles
| Name | Description | Version | OS Requirements | Dependencies |
| ---- | ----------- | ------- | --- | ---|
| [logging.stack](https://gitlab.com/ska-telescope/sdi/ska-ser-ansible-collections/-/tree/main/ansible_collections/ska_collections/logging/roles/stack) | Install Elasticsearch cluster, Kibana and HA | 8.4.2 | Ubuntu 18+ (LTS) | [common.certs](https://gitlab.com/ska-telescope/sdi/ska-ser-ansible-collections/-/tree/main/ansible_collections/ska_collections/common/roles/certs) |
| [logging.haproxy](https://gitlab.com/ska-telescope/sdi/ska-ser-ansible-collections/-/tree/main/ansible_collections/ska_collections/logging/roles/haproxy) | Install and configure SSL certificates | 2.6 | Ubuntu 18+ (LTS) | |
| [logging.beats](https://gitlab.com/ska-telescope/sdi/ska-ser-ansible-collections/-/tree/main/ansible_collections/ska_collections/logging/roles/beats) | Install and configure SSL certificates | 7.17.0 | Ubuntu 18+ (LTS) | |

## Installation

### SKA Nexus Repository

Before using the collection, you need to install the collection with the `ansible-galaxy` CLI:

    ansible-galaxy collection install ska_collections.logging

You can also include it in a `requirements.yml` file and install it via ansible-galaxy collection install -r requirements.yml` using the format:

```yaml
collections:
- name: ska_collections.logging
```

## Usage

Playbooks can be found in the [playbooks/](https://gitlab.com/ska-telescope/sdi/ska-ser-ansible-collections/-/tree/main/ansible_collections/ska_collections/logging/playbooks) folder in the following files:

| Name | Description |
| ---- | ----------- |
| [install.yml](https://gitlab.com/ska-telescope/sdi/ska-ser-ansible-collections/-/blob/1441ec87eebf5e0ea3a579a25761449f7f853a94/ansible_collections/ska_collections/logging/playbooks/common.yml) | Install Elasticsearch cluster, Kibana and HA  |
| [destroy.yml](https://gitlab.com/ska-telescope/sdi/ska-ser-ansible-collections/-/blob/1441ec87eebf5e0ea3a579a25761449f7f853a94/ansible_collections/ska_collections/logging/playbooks/destroy.yml) | Destroys Elastic Stack |
| [destroy-logging.yml](https://gitlab.com/ska-telescope/sdi/ska-ser-ansible-collections/-/blob/1441ec87eebf5e0ea3a579a25761449f7f853a94/ansible_collections/ska_collections/logging/playbooks/destroy-logging.yml) | Destroys Filebeat |
| [list-api-keys.yml](https://gitlab.com/ska-telescope/sdi/ska-ser-ansible-collections/-/blob/1441ec87eebf5e0ea3a579a25761449f7f853a94/ansible_collections/ska_collections/logging/playbooks/list-api-keys.yml) | Lists Elasticsearch API keys |
| [logging.yml](https://gitlab.com/ska-telescope/sdi/ska-ser-ansible-collections/-/blob/1441ec87eebf5e0ea3a579a25761449f7f853a94/ansible_collections/ska_collections/logging/playbooks/logging.yml) | Installs Filebeat|
| [update-api-keys.yml](https://gitlab.com/ska-telescope/sdi/ska-ser-ansible-collections/-/blob/1441ec87eebf5e0ea3a579a25761449f7f853a94/ansible_collections/ska_collections/logging/playbooks/logging.yml) | Updates the API keys |

In order to run these playbooks, it's needed to specify the Ansible Inventory location and the respective group/hosts ***target_hosts*** variable.

Run **install** playbook as an example:
```
ansible-playbook <playbooks-folder-path>/install.yml \
	-i $(INVENTORY) \
	--extra-vars "target_hosts=<target-hosts>"
```

> To run the playbooks on every host available on the inventory select **all** as *target_hosts*

### Required variables

| Name | Ansible variable | Obs |
| ---- | ----------- | ----- |
| Elasticsearch cluster DNS Name | elasticsearch_dns_name | Same dns name used on the certificates |
| Target Elasticsearch Cluster address | logging_filebeat_elasticsearch_address | Domain or ip of the target elasticsearch cluster (preferably, the loadbalancer) |

### Required secrets

| Name | Ansible variable | ENV variable | Obs |
| ---- | ----------- | ------------ | ----- |
| Certificate Authority Password | ca_cert_password | CA_CERT_PASSWORD | |
| Elasticsearch Admin Password | elasticsearch_password | ELASTICSEARCH_PASSWORD | |
| Kibana User Password | kibana_viewer_password | KIBANA_VIEWER_PASSWORD | |
| Elasticsearch HA Stats password | elastic_haproxy_stats_password | ELASTIC_HAPROXY_STATS_PASSWORD | |
| Filebeat authentication password | logging_filebeat_elasticsearch_password | LOGGING_FILEBEAT_API_KEY | logging_filebeat_elasticsearch_auth_method: 'basic' -> Plain password <br><br> logging_filebeat_elasticsearch_auth_method: 'api-key' -> base64-decoded issued by `elasticsearch_api_keys`|

## How to Contribute

### Adding a new role
A new role can be added to the [roles](./roles/) folder and then included into a new and/or existing playbook.

### Updating an existing role
The existing roles can be found in the [roles](./roles/) folder. To update a role, the role's tasks can be simply modified.

### External dependencies
Go to [requirements.yml](../../../requirements.yml) and [galaxy.yml](./galaxy.yml) files to add or update any external dependency.

### Add/Update new variables
Ansible variables that are datacentre specific should be added to the `group_vars` folder of the inventory.

To modify non-secret variable role defaults, go to the defaults folder of the respective role and update them. As an [example](./roles/stack/defaults/main.yml).

Finally, the secret variables are defined in the respective [Makefile](../../../resources/jobs/logging.mk) and can be modified there. To assign proper values to these variables, please use a `PrivateRules.mak` file.

## More information

- [Ansible Using collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html)
- [Ansible Collection overview](https://github.com/ansible-collections/overview)
- [Ansible User guide](https://docs.ansible.com/ansible/latest/user_guide/index.html)
- [Ansible Developer guide](https://docs.ansible.com/ansible/latest/dev_guide/index.html)
- [Ansible Community code of conduct](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html)

## License

BSD-3.
# SKA Nexus Collection

This collection includes a variety of Ansible roles to help automate the installation and configuration of Nexus OSS edition  using an adapted version of [link](https://github.com/ansible-ThoTeam/nexus3-oss). 

The changes are found in the `./resources` directory, and are used to overwrite the `../../ansible_collections/ansible-thoteam.nexus3-oss` role.


This collection is currently maintained by [SKAO](https://www.skao.int/).

## Ansible

Tested with the current Ansible 6.5.x releases.

## Ansible Roles
| Name | Description | Version | OS Requirements | Dependencies |
| ---- | ----------- | ------- | --- | ---|
| [nexus.common](./roles/common) | Requirements installation and configurations | | Ubuntu 18+ (LTS) | |
| [nexus.haproxy](./roles/haproxy) | Deploys HA Proxy | 2.4 | Ubuntu 18+ (LTS) | Docker |
| [nexus.nexus3-conan](./roles/beats) | Installs Nexus | 3.x | Ubuntu 18+ (LTS) | ansible-thoteam.nexus3-oss |

## Production site

The production Nexus instance for the Central Artefact Repository is hosted at https://artefact.skatelescope.org/.  This is integrated with SKAO LDAP based authentication for administration access - all other service accounts are maintained as local users.
## Installation



Before using the collection, you need to install the collection with the `ansible-galaxy` CLI:

    ansible-galaxy collection install ska_collections.nexus

You can also include it in a `requirements.yml` file and install it via ansible-galaxy collection install -r requirements.yml` using the format:

```yaml
collections:
- name: ska_collections.nexus
```

## Usage

Playbooks can be found in the [playbooks/](./playbooks) folder in the following files:

| Name | Description |
| ---- | ----------- |
| [deploy.yml](./playbooks/deploy.yml) | Deploys Nexus |

In order to run these playbooks, it's needed to specify the Ansible Inventory location and the respective group/hosts ***target_hosts*** variable.

Run **deploy** playbook as an example:
```
ansible-playbook <playbooks-folder-path>/deploy.yml \
	-i $(INVENTORY) \
	--extra-vars "target_hosts=<target-hosts>"
```


### Required secrets

| Name | Ansible variable | ENV variable | Obs |
| ---- | ----------- | ------------ | ----- |
| Nexus Admin Password | nexus_admin_password | NEXUS_ADMIN_PASSWORD | |
| Nexus Gitlab User Password | nexus_gitlab_password | NEXUS_GITLAB_PASSWORD | |
| Nexus Publisher User Password | nexus_publisher_password | NEXUS_PUBLISHER_PASSWORD | |
| Nexus Quarantiner Password | nexus_quarantiner_password | NEXUS_QUARANTINER_PASSWORD | |
| Nexus Webhook Key | nexus_webhook_secret_key | NEXUS_WEBHOOK_SECRET_KEY | |
| Nexus Email Server Password | nexus_email_server_password | NEXUS_EMAIL_SERVER_PASSWORD | |
| Nexus SKAO LDAP Password | nexus_skao_ad_ldap_password | NEXUS_SKAO_AD_LDAP_PASSWORD | |
| Nexus HAProxy Stats Password | nexus_haproxy_stats_password | NEXUS_HAPROXY_STATS_PASSWORD | |

## How to Contribute

### Adding a new role
A new role can be added to the [roles](./roles/) folder and then included into the nexus playbook in the [deploy.yml](./playbooks/deploy.yml) file.

### Updating an existing role
The existing roles can be found in the [roles](./roles/) folder and are already included into the nexus playbook in the [deploy.yml](./playbooks/deploy.yml) file. To update a role, the role's tasks can be simply modified.

This collection does have an external role dependency, `ansible-thoteam.nexus3-oss`, which can be installed using the main Makefile of this repository. To update this role, a new version may be specified in the [requirements.yml](../../../requirements.yml) and [galaxy.yml](./galaxy.yml) files.

### Add/Update new variables
Ansible variables that are datacentre specific should be added to the `host_vars` folder of the inventory.

To modify non-secret variable defaults, the [deploy.yml](./playbooks/deploy.yml) file defines them in the `vars` field of the `Nexus install` task.

Finally, the secret variables are defined in the Nexus [Makefile](../../../resources/jobs/nexus.mk) and can be modified there. To assign proper values to these variables, please use a `PrivateRules.mak` file.

## More information

- [Ansible Using collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html)
- [Ansible Collection overview](https://github.com/ansible-collections/overview)
- [Ansible User guide](https://docs.ansible.com/ansible/latest/user_guide/index.html)
- [Ansible Developer guide](https://docs.ansible.com/ansible/latest/dev_guide/index.html)
- [Ansible Community code of conduct](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html)

## License

BSD-3.
# SKA Instance Common Collection

This collection has tasks that are common for every instance maintained by currently maintained by [SKAO](https://www.skao.int/).

## Ansible

Tested with the current Ansible 6.5.x releases.

## Ansible Roles
| Name | Description | Version | OS Requirements | Dependencies |
| ---- | ----------- | ------- | --- | ---|
| [instance_common.init](./roles/init) | Install apt dependencies <br> Mounts volumes <br> Updates hosts | latest | Ubuntu 18+ (LTS) | |
| [instance_common.certs](./roles/certs) | Install and configure SSL certificates | latest | Ubuntu 18+ (LTS) | |

## Installation



Before using the collection, you need to install the collection with the `ansible-galaxy` CLI:

    ansible-galaxy collection install ska_collections.instance_common

You can also include it in a `requirements.yml` file and install it via ansible-galaxy collection install -r requirements.yml` using the format:

```yaml
collections:
- name: ska_collections.instance_common
```

## Usage

Playbooks can be found in the [playbooks/](./playbooks) folder in the following files:

| Name | Description |
| ---- | ----------- |
| [common.yml](./playbooks/common.yml) | Install apt dependencies <br> Mounts volumes <br> Updates hosts |
| [setup-ca.yml](./playbooks/setup-ca.yml) | Setups Certificate Authority |
| [sign.yml](./playbooks/sign.yml) | Signs instance certificates |
| [update-hosts.yml](./playbooks/update-hosts.yml) | Updates Hosts file |

In order to run these playbooks, it's needed to specify the Ansible Inventory location and the respective group/hosts ***target_hosts*** variable.

Run **common** playbook as an example:
```
ansible-playbook <playbooks-folder-path>/common.yml \
	-i $(INVENTORY) \
	--extra-vars "target_hosts=<target-hosts>"
```

> To run the playbooks on every host available on the inventory select **all** as *target_hosts*

### Required secrets

| Name | Ansible variable | ENV variable |
| ---- | ----------- | ------------ |
| Certificate Authority Password | ca_cert_password | CA_CERT_PASSWORD |


## How to Contribute

### Adding a new role
A new role can be added to the [roles](./roles/) folder and then included into a new and/or existing playbook.

### Updating an existing role
The existing roles can be found in the [roles](./roles/) folder. To update a role, the role's tasks can be simply modified.

### External dependencies
Go to [requirements.yml](../../../requirements.yml) and [galaxy.yml](./galaxy.yml) files to add or update any external dependency.

### Add/Update new variables
Ansible variables that are datacentre specific should be added to the `group_vars` folder of the inventory.

To modify non-secret variable role defaults, go to the defaults folder of the respective role and update them. As an [example](./roles/init/defaults/main.yml).

Finally, the secret variables are defined in the respective [Makefile](../../../resources/jobs/common.mk) and can be modified there. To assign proper values to these variables, please use a `PrivateRules.mak` file.

## More information

- [Ansible Using collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html)
- [Ansible Collection overview](https://github.com/ansible-collections/overview)
- [Ansible User guide](https://docs.ansible.com/ansible/latest/user_guide/index.html)
- [Ansible Developer guide](https://docs.ansible.com/ansible/latest/dev_guide/index.html)
- [Ansible Community code of conduct](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html)

## License

BSD-3.
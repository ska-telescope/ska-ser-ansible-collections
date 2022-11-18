# SKA Ceph Ansible Collection

This collection includes a variety of Ansible roles to help automate the installation and configuration of [Ceph](https://docs.ceph.com/en/quincy/) - open-source software-defined storage platform.
This collection is currently maintained by [SKAO](https://www.skao.int/) and it's a wrapper of [Cephadm Collection](https://github.com/stackhpc/ansible-collection-cephadm) by [StackHPC](https://www.stackhpc.com/).

## Ansible

Tested with the current Ansible 6.5.x releases.

## Ansible Roles
| Name | Description | Version | OS Requirements | Dependencies |
| ---- | ----------- | ------- | --- | ---|
| [ceph.installation](./roles/installation) | Install and configure Ceph | 20.10.18 | Ubuntu 18+ (LTS) | [stackhpc.cephadm](https://galaxy.ansible.com/stackhpc/cephadm) v1.10.0

## Installation

### SKA Nexus Repository

Before using the collection, you need to install the collection with the `ansible-galaxy` CLI:

    ansible-galaxy collection install ska_collections.ceph

You can also include it in a `requirements.yml` file and install it via ansible-galaxy collection install -r requirements.yml` using the format:

```yaml
collections:
- name: ska_collections.ceph
```

## Usage

Installation playbooks for each engine can be found in the [playbooks/](./playbooks) folder in the following files:

| Name | Description |
| ---- | ----------- |
| [install.yml](./playbooks/install.yml) | Install Ceph |

In order to run these playbooks, it's needed to specify the Ansible Inventory location and the respective group/hosts ***target_hosts*** variable.

Install **Ceph** as an example:
```
ansible-playbook <playbooks-folder-path>/install.yml \
	-i $(INVENTORY) \
	--extra-vars "target_hosts=<target-hosts>"
```

> To run the playbooks on every host available on the inventory select **all** as *target_hosts*

## How to Contribute

### Adding a new role
A new role can be added to the [roles](./roles/) folder and then included into a new and/or existing playbook.

### Updating an existing role
The existing roles can be found in the [roles](./roles/) folder. To update a role, the role's tasks can be simply modified.

### External dependencies
Go to [requirements.yml](../../../requirements.yml) and [galaxy.yml](./galaxy.yml) files to add or update any external dependency.

### Add/Update new variables
Ansible variables that are datacentre specific should be added to the `group_vars` folder of the inventory.

To modify non-secret variable role defaults, go to the defaults folder of the respective role and update them. As an [example](./roles/installation/defaults/main.yml).

Finally, the secret variables are defined in the respective [Makefile](../../../resources/jobs/ceph.mk) and can be modified there. To assign proper values to these variables, please use a `PrivateRules.mak` file.

## More information

- [Ansible Using collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html)
- [Ansible Collection overview](https://github.com/ansible-collections/overview)
- [Ansible User guide](https://docs.ansible.com/ansible/latest/user_guide/index.html)
- [Ansible Developer guide](https://docs.ansible.com/ansible/latest/dev_guide/index.html)
- [Ansible Community code of conduct](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html)

## License

BSD-3.
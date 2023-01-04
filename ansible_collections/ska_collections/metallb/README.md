# SKA Metallb Ansible Collection

This collection includes a variety of Ansible roles to help automate the installation and configuration of [Metallb](https://metallb.universe.tf/).

This collection is currently maintained by [SKAO](https://www.skao.int/).

## Ansible

Tested with the current Ansible 6.5.x releases.

## Ansible Roles
| Name | Description | Version | OS Requirements | Dependencies |
| ---- | ----------- | ------- | --- | ---|
| [Metallb](./roles/metallb) | Install and configure metallb | - | Ubuntu 18+ (LTS) | -

## Notes
We have 2 playbooks: 
 - One is to disable openstack security port. (use only if needed, see description in the playbook ./playbooks/metallb_openstack)
 - The other is to install metallb via helm chart. The helm chart used is this: https://github.com/bitnami/charts/tree/main/bitnami/metallb

## Vars
Check the ./roles/defaults/main.yml to validate the needed variables

- ***metallb_address_pools*** is the ips range used by the loadbalancer.

## Installation

In order to run these playbooks, it's needed to specify the Ansible Inventory location and the respective group/hosts ***target_hosts*** variable.

The ***target_hosts*** to disable openstack security port should be one of the openstack nodes (ex: openstack[0])
The ***target_hosts*** for the metallb instalation should be one of the kubernetes nodes (ex: master[0])

Install **metallb** as:
```
ansible-playbook <playbooks-folder-path>/dns/playbooks/metallb.yml \
	-i $(INVENTORY) \
	--extra-vars "target_hosts=<target-hosts>"
```

## More information

- [Ansible Using collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html)
- [Ansible Collection overview](https://github.com/ansible-collections/overview)
- [Ansible User guide](https://docs.ansible.com/ansible/latest/user_guide/index.html)
- [Ansible Developer guide](https://docs.ansible.com/ansible/latest/dev_guide/index.html)
- [Ansible Community code of conduct](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html)

## License

BSD-3.

Also see a [full explanation and example](https://robertdebock.nl/how-to-use-these-roles.html) on how to use these roles.



# SKA DNS Ansible Collection

This collection includes a variety of Ansible roles to help automate the installation and configuration of [dnsmasq](https://thekelleys.org.uk/dnsmasq/doc.html).

This collection is currently maintained by [SKAO](https://www.skao.int/).

## Ansible

Tested with the current Ansible 6.5.x releases.

## Ansible Roles
| Name | Description | Version | OS Requirements | Dependencies |
| ---- | ----------- | ------- | --- | ---|
| [dns](./roles/dns) | Install and configure dnsmasq | 2.79 (Bionic), 2.80 (Focal), 2.86 (Jammy) | Ubuntu 18+ (LTS) | -

##
Make sure you have the variables in the hostvars for the target_host

ex:
***dns_addvertise_domain***: skao.stfc
(fill array if you want custom domains added to your configuration)
***dns_server_addresses***:
	- name: test.skao.stfc
	  address: 192.168.XX.XX

## Installation

In order to run these playbooks, it's needed to specify the Ansible Inventory location and the respective group/hosts ***target_hosts*** variable.

Install **dns** as:
```
ansible-playbook <playbooks-folder-path>/dns/playbooks/dns_server.yml \
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
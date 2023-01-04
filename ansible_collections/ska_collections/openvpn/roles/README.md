# SKA OpenVPN Ansible Collection

This collection includes a variety of Ansible roles to help automate the installation and configuration of [openvpn](https://community.openvpn.net/openvpn).

This collection is currently maintained by [SKAO](https://www.skao.int/).

## Ansible

Tested with the current Ansible 6.5.x releases.

## Ansible Roles
| Name | Description | Version | OS Requirements | Dependencies |
| ---- | ----------- | ------- | --- | ---|
| [openvpn](./roles/openvpn) | Install and configure openvpn | 2.4.4 (Bionic), 2.4.7 (Focal), 2.6.0 (Jammy) | Ubuntu 18+ (LTS) | -

## Installation

In order to run these playbooks, it's needed to specify the Ansible Inventory location and the respective group/hosts ***target_hosts*** variable.

Install **openvpn** as:
```
ansible-playbook <playbooks-folder-path>/dns/playbooks/openvpn_server.yml \
	-i $(INVENTORY) \
	--extra-vars "target_hosts=<target-hosts>"
```

## [Role Variables](#role-variables)

These variables are set in `defaults/main.yml`:
```yaml
---
# defaults file for openvpn

# You can setup both a client and a server using this role.
# Use `server` or `client` for `openvpn role`.

openvpn_role: server

# If you are configuring a client, setup these variables:
# openvpn_role: client
# openvpn_client_server: vpn.example.com
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



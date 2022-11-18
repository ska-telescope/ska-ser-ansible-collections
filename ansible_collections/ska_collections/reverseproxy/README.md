# SKA Reverse Proxy Ansible Collection

This collection includes a variety of Ansible roles to help automate the installation and configuration of the reverse proxy.


This collection is currently maintained by [SKAO](https://www.skao.int/).

## Ansible

Tested with the current Ansible 6.5.x releases.

## Ansible Roles
| Name | Description | Version | OS Requirements | Dependencies |
| ---- | ----------- | ------- | --- | ---|
| [reverseproxy.reverseproxy](./roles/reverseproxy) | Install Reverse Proxy | | Ubuntu 18+ (LTS) | |

## Installation

### SKA Nexus Repository

Before using the collection, you need to install the collection with the `ansible-galaxy` CLI:

    ansible-galaxy collection install ska_collections.reverseproxy

You can also include it in a `requirements.yml` file and install it via ansible-galax collection install -r requirements.yml` using the format:

```yaml
collections:
- name: ska_collections.reverseproxy
```

## Usage

Playbooks can be found in the [playbooks/](./playbooks) folder in the following files:

| Name | Description |
| ---- | ----------- |
| [install.yml](./playbooks/install.yml) | Install Reverse Proxy  |
| [destroy.yml](./playbooks/destroy.yml) | Destroy Reverse Proxy  |

In order to run these playbooks, it's needed to specify the Ansible Inventory location and the respective group/hosts ***target_hosts*** variable.

Run **install** playbook as an example:
```
ansible-playbook <playbooks-folder-path>/install.yml \
	-i $(INVENTORY) \
	--extra-vars "target_hosts=<target-hosts>"
```

> To run the playbooks on every host available on the inventory select **all** as *target_hosts*

### Required variables

| Name | Ansible variable | ENV variable | Obs |
| ---- | ----------- | ----- | ----- |
| Reverse Proxy DNS name | reverseproxy_dns_name | | Should be set to the dns name of the reverse proxy (also used to issue self-signed certificates when needed) |
| Reverse Proxy AzureAD OAuth2 Client ID | reverseproxy_oauth2proxy_client_id | | Should be set to the client id of the oauth2proxy |
| Reverse Proxy AzureAD OAuth2 Tenant ID | reverseproxy_oauth2proxy_tenant_id | | Should be set to the tenant id of the oauth2proxy |


### Required secrets

| Name | Ansible variable | ENV variable | Obs |
| ---- | ----------- | ------------ | ----- |
| Reverse Proxy AzureAD OAuth2 Cookie Secret | reverseproxy_oauth2proxy_cookie_secret | AZUREAD_COOKIE_SECRET | Should be set to the cookie secret used for the oauth2proxy |
| Reverse Proxy AzureAD OAuth2 Client Secret | reverseproxy_oauth2proxy_client_secret | AZUREAD_CLIENT_SECRET | Should be set to the client secret used for the oauth2proxy |

## How to Contribute

### Adding a new role
A new role can be added to the [roles](./roles/) folder and then included into a new and/or existing playbook.

### Updating an existing role
The existing roles can be found in the [roles](./roles/) folder. To update a role, the role's tasks can be simply modified.

### External dependencies
Go to [requirements.yml](../../../requirements.yml) and [galaxy.yml](./galaxy.yml) files to add or update any external dependency.

### Add/Update new variables
Ansible variables that are datacentre specific should be added to the `group_vars` folder of the inventory.

To modify non-secret variable role defaults, go to the defaults folder of the respective role and update them. As an [example](./roles/reverseproxy/defaults/main.yml).

Finally, the secret variables are defined in the respective [Makefile](../../../resources/jobs/reverseproxy.mk) and can be modified there. To assign proper values to these variables, please use a `PrivateRules.mak` file.

## More information

- [Ansible Using collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html)
- [Ansible Collection overview](https://github.com/ansible-collections/overview)
- [Ansible User guide](https://docs.ansible.com/ansible/latest/user_guide/index.html)
- [Ansible Developer guide](https://docs.ansible.com/ansible/latest/dev_guide/index.html)
- [Ansible Community code of conduct](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html)

## License

BSD-3.

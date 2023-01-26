# SKA Gateway Ansible Collection

This collection registers and runs a couple of playbooks to configure the Gateway.
This collection is currently maintained by [SKAO](https://www.skao.int/).

## Ansible

Tested with the current Ansible 6.5.x releases.

## Ansible Roles
| Name | Description | Version | OS Requirements | Dependencies |
| ---- | ----------- | ------- | --- | ---|
| [gateway.cron](./roles/cron) | Install and configure cronjobs | latest | Ubuntu 18+ (LTS) | 
| [gateway.jumphost](./roles/cron) | Configure User Accounts and ssh keys | latest | Ubuntu 18+ (LTS) | 
| [gateway.openvpn](./roles/openvpn) | Install and configure openvpn | 2.4.4 (Bionic), 2.4.7 (Focal), 2.6.0 (Jammy) | Ubuntu 18+ (LTS) | -
| [reverseproxy.reverseproxy](./roles/reverseproxy) | Install Reverse Proxy | | Ubuntu 18+ (LTS) | |
| [dns](./roles/dns) | Install and configure dnsmasq | 2.79 (Bionic), 2.80 (Focal), 2.86 (Jammy) | Ubuntu 18+ (LTS) | -

## Installation


Before using the collection, you need to install the collection with the `ansible-galaxy` CLI:

    ansible-galaxy collection install ska_collections.gateway

You can also include it in a `requirements.yml` file and install it via ansible-galaxy collection install -r requirements.yml` using the format:

```yaml
collections:
- name: ska_collections.gateway
```

## Usage

Installation playbooks for each engine can be found in the [playbooks/](./playbooks) folder in the following files:

| Name | Description |
| ---- | ----------- |
| [cron_add_configure_cronjob.yml](./playbooks/add_configure_cronjob.yml) | Install and Configure Cron |
| [jumphost_configure_user_access.yml](./playbooks/configure_user_access.yml) | Configure User Account access to gateway |
| [openvpn_server.yml](./playbooks/openvpn_server.yml) | Deploy Openvpn Server |
| [openvpn_add_client.yml](./playbooks/openvpn_add_client.yml) | Adds new client to openvpn server |
| [openvpn_remove_client.yml](./playbooks/openvpn_remove_client.yml) | Configure User Account access to gateway |
| [reverse_proxy_install.yml](./playbooks/install.yml) | Install Reverse Proxy  |
| [reverse_proxy_destroy.yml](./playbooks/destroy.yml) | Destroy Reverse Proxy  |
| [dns_server.yml](./playbooks/dns_server.yml) | Install DNS Server  |
| [dns_server_destroy.yml](./playbooks/dns_server_destroy.yml) | Destroy DNS Server  |


In order to run these playbooks, it's needed to specify the Ansible Inventory location and the respective group/hosts ***target_hosts*** variable.

Install **Cron** as an example:
```
ansible-playbook <playbooks-folder-path>/add_configure_cronjob.yml \
	-i $(INVENTORY) \
	--extra-vars "target_hosts=<target-hosts>"
```

### Required variables

#### Reverse Proxy

| Name | Ansible variable | ENV variable | Obs |
| ---- | ----------- | ----- | ----- |
| Reverse Proxy DNS name | reverseproxy_dns_name | | Should be set to the dns name of the reverse proxy (also used to issue self-signed certificates when needed) |
| Reverse Proxy AzureAD OAuth2 Client ID | reverseproxy_oauth2proxy_client_id | | Should be set to the client id of the oauth2proxy |
| Reverse Proxy AzureAD OAuth2 Tenant ID | reverseproxy_oauth2proxy_tenant_id | | Should be set to the tenant id of the oauth2proxy |


### Required secrets

#### Reverse Proxy

| Name | Ansible variable | ENV variable | Obs |
| ---- | ----------- | ------------ | ----- |
| Reverse Proxy AzureAD OAuth2 Cookie Secret | reverseproxy_oauth2proxy_cookie_secret | AZUREAD_COOKIE_SECRET | Should be set to the cookie secret used for the oauth2proxy |
| Reverse Proxy AzureAD OAuth2 Client Secret | reverseproxy_oauth2proxy_client_secret | AZUREAD_CLIENT_SECRET | Should be set to the client secret used for the oauth2proxy |

## Current services deployed in STFC-Techops Gateway

- Reverse proxy - [install.yml](roles/reverseproxy/playbooks/install.yml)
- DNS Server - [dns_server.yml](roles/dns/playbooks/dns_server.yml)
- Openvpn Server TCP/UDP - [openvpn_server.yml](roles/openvpn/playbooks/openvpn_server.yml)
- Docker/Containerd/Podman - [docker_base](roles/docker_base)
- Certificate Authoraty - [setup-ca.yml](roles/instance_common/playbooks/setup-ca.yml)
- Cron Jobs - [add_configure_cronjob.yml](./playbooks/add_configure_cronjob.yml)
- Node exporter, docker exporter - [deploy_node_exporter.yml](roles/monitoring/playbooks/deploy_node_exporter.yml)
- Jumphost - [configure_user_access.yml](./playbooks/configure_user_access.yml)


## How to Contribute

### Adding a new role
A new role can be added to the [roles](./roles/) folder and then infcluded into a new and/or existing playbook.

### Updating an existing role
The existing roles can be found in the [roles](./roles/) folder. To update a role, the role's tasks can be simply modified.

### External dependencies
Go to [requirements.yml](../../../requirements.yml) and [galaxy.yml](./galaxy.yml) files to add or update any external dependency.

### Add/Update new variables
Ansible variables that are datacentre specific should be added to the `group_vars` folder of the inventory.

To modify non-secret variable role defaults, go to the defaults folder of the respective role and update them. As an [example](./roles/cron/defaults/main.yml).

Finally, the secret variables are defined in the respective [Makefile](../../../resources/jobs/gateway.mk) and can be modified there. To assign proper values to these variables, please use a `PrivateRules.mak` file.

## More information

- [Ansible Using collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html)
- [Ansible Collection overview](https://github.com/ansible-collections/overview)
- [Ansible User guide](https://docs.ansible.com/ansible/latest/user_guide/index.html)
- [Ansible Developer guide](https://docs.ansible.com/ansible/latest/dev_guide/index.html)
- [Ansible Community code of conduct](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html)
## License

BSD-3.
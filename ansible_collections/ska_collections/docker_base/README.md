# SKA Ansible Docker Base collection

This collection includes a variety of Ansible roles to help automate the installation and configuration of OCI engines.
This collection is currently maintained by [SKAO](https://www.skao.int/).

## Ansible

Tested with the current Ansible 6.5.x releases.

## Ansible Roles
| Name | Description | Version | OS Requirements |
| ---- | ----------- | ------- | --- |
| [docker_base.docker](./roles/docker) | Install and configure Docker | 20.10.18 | Ubuntu 18+ (LTS)
| [docker_base.podman](./roles/podman) | Install and configured Podman| 4.3.0 | Ubuntu 18+ (LTS)
| [docker_base.containerd](./roles/containerd) | Install and configured Containerd| 1.6.6 | Ubuntu 18+ (LTS) |

## Installation


### SKA Nexus Repository

Before using the collection, you need to install the collection with the `ansible-galaxy` CLI:

    ansible-galaxy collection install ska_collections.docker_base

You can also include it in a `requirements.yml` file and install it via ansible-galax collection install -r requirements.yml` using the format:

```yaml
collections:
- name: ska_collections.docker_base
```


### Git

Pull the latest edge commit of the SKA Ansible Collections from Gitlab:

```
git clone https://gitlab.com/ska-telescope/sdi/ska-ser-ansible-collections.git
```

## Usage

Installation playbooks for each engine can be found in the [playbooks/](./playbooks) folder in the following files:

| Name | Description |
| ---- | ----------- |
| [containers.yml](./playbooks/containers.yml) | Install all supported engines: Docker, Podman, ContainerD|
| [docker.yml](./playbooks/docker.yml) | Install Docker |
| [podman.yml](./playbooks/podman.yml) | Install and Podman|
| [containerd.yml](./playbooks/containerd.yml) | Install Containerd|

In order to run these playbooks, it's needed to specify the Ansible Inventory location and the respective group/hosts ***target_hosts*** variable.

Install **Docker** as an example:
```
ansible-playbook <playbooks-folder-path>/docker.yml \
	-i $(INVENTORY) \
	--extra-vars "target_hosts=<target-hosts>"
```

> To run the playbook on every host in the inventory select **all** as *target_hosts*

## How to Contribute

### Adding a new role
A new role can be added to the [roles](./roles/) folder and then included into a new and/or existing playbook.

### Updating an existing role
The existing roles can be found in the [roles](./roles/) folder. To update a role, the role's tasks can be simply modified.

### External dependencies
Go to [requirements.yml](../../../requirements.yml) and [galaxy.yml](./galaxy.yml) files to add or update any external dependency.

### Add/Update new variables
Ansible variables that are datacentre specific should be added to the `group_vars` folder of the inventory.

To modify non-secret variable role defaults, go to the defaults folder of the respective role and update them. As an [example](./roles/docker/defaults/main.yml).

Finally, the secret variables are defined in the respective [Makefile](../../../resources/jobs/oci.mk) and can be modified there. To assign proper values to these variables, please use a `PrivateRules.mak` file.

## More information

- [Ansible Using collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html)
- [Ansible Collection overview](https://github.com/ansible-collections/overview)
- [Ansible User guide](https://docs.ansible.com/ansible/latest/user_guide/index.html)
- [Ansible Developer guide](https://docs.ansible.com/ansible/latest/dev_guide/index.html)
- [Ansible Community code of conduct](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html)

## License

BSD-3.
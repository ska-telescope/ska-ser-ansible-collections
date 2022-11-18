# Ansible Collection - ska_collections.minikube

This directory contains the `ska_collections.minikube` Ansible Collection. The collection includes roles and playbooks for `minikube` based Kubernetes deployments.

## Ansible

Tested with the current Ansible 6.5.x releases.

## Ansible Roles
| Name | Description | Version | OS Requirements | Dependencies |
| ---- | ----------- | ------- | --- | ---|
| [minikube.minikube](./roles/minikube) | deploying an instance of minikube and haproxy | Kubernetes: 1.25.2 <br> HA: 2.6 | Ubuntu 18+ (LTS) | |
| [minikube.setup](./roles/setup) | Installing Minikube dependencies and useful tools - minikube, kubectl, helm, yq and k9s| Minikube: 1.27.1 <br> Kubernetes: 1.25.2 <br> Helm: 3.10.1 <br> K9s: 0.26.6 <br> yq: 4.27.3 | Ubuntu 18+ (LTS) | |
| [minikube.velero](./roles/velero) | Install Velero backup manager | 1.9.2 | Ubuntu 18+ (LTS) | |

## Installation



Before using the collection, you need to install the collection with the `ansible-galaxy` CLI:

    ansible-galaxy collection install ska_collections.minikube

You can also include it in a `requirements.yml` file and install it via ansible-galaxy collection install -r requirements.yml` using the format:

```yaml
collections:
- name: ska_collections.minikube
```


## Usage

Playbooks can be found in the [playbooks/](./playbooks) folder in the following files:

| Name | Description |
| ---- | ----------- |
| [minikube.yml](./playbooks/minikube.yml) | Runs setup role and then minikube |
| [destroy.yml](./playbooks/velero_backups.yml) | Install Velero |


In order to run these playbooks, it's needed to specify the Ansible Inventory location and the respective group/hosts ***target_hosts*** variable.

Run **minikube** playbook as an example:
```
ansible-playbook <playbooks-folder-path>/minikube.yml \
	-i $(INVENTORY) \
	--extra-vars "target_hosts=<target-hosts>"
```

> To run the playbooks on every host available on the inventory select **all** as *target_hosts*

<!-- ### Required variables

| Name | Ansible variable | Obs |
| ---- | ----------- | ----- |


### Required secrets

| Name | Ansible variable | ENV variable | Obs |
| ---- | ----------- | ------------ | ----- | -->

## How to Contribute

### Adding a new role
A new role can be added to the [roles](./roles/) folder and then included into a new and/or existing playbook.

### Updating an existing role
The existing roles can be found in the [roles](./roles/) folder. To update a role, the role's tasks can be simply modified.

### External dependencies
Go to [requirements.yml](../../../requirements.yml) and [galaxy.yml](./galaxy.yml) files to add or update any external dependency.

### Add/Update new variables
Ansible variables that are datacentre specific should be added to the `group_vars` folder of the inventory.

To modify non-secret variable role defaults, go to the defaults folder of the respective role and update them. As an [example](./roles/setup/defaults/main.yml).

<!-- Finally, the secret variables are defined in the respective [Makefile](../../../resources/jobs/logging.mk) and can be modified there. To assign proper values to these variables, please use a `PrivateRules.mak` file. -->


## More information

- [Ansible Using collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html)
- [Ansible Collection overview](https://github.com/ansible-collections/overview)
- [Ansible User guide](https://docs.ansible.com/ansible/latest/user_guide/index.html)
- [Ansible Developer guide](https://docs.ansible.com/ansible/latest/dev_guide/index.html)
- [Ansible Community code of conduct](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html)

## Licensing

BSD-3.


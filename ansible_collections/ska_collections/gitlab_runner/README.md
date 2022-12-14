# SKA Gitlab Runner Ansible Collection

This collection registers and runs a single [gitlab-runner](https://docs.gitlab.com/runner/) using docker.
This collection is currently maintained by [SKAO](https://www.skao.int/).

## Ansible

Tested with the current Ansible 6.5.x releases.

## Ansible Roles
| Name | Description | Version | OS Requirements | Dependencies |
| ---- | ----------- | ------- | --- | ---|
| [gitlab_runner.runner](./roles/runner) | Install and configure Runner | latest | Ubuntu 18+ (LTS) | |

## Installation



Before using the collection, you need to install the collection with the `ansible-galaxy` CLI:

    ansible-galaxy collection install ska_collections.gitlab_runner

You can also include it in a `requirements.yml` file and install it via ansible-galaxy collection install -r requirements.yml` using the format:

```yaml
collections:
- name: ska_collections.gitlab_runner
```

## Usage

Installation playbooks for each engine can be found in the [playbooks/](./playbooks) folder in the following files:

| Name | Description |
| ---- | ----------- |
| [install.yml](./playbooks/install.yml) | Install Gitlab runner |

In order to run these playbooks, it's needed to specify the Ansible Inventory location and the respective group/hosts ***target_hosts*** variable.

Install **Runner** as an example:
```
ansible-playbook <playbooks-folder-path>/install.yml \
	-i $(INVENTORY) \
	--extra-vars "target_hosts=<target-hosts>"
```


### Required secrets

| Name | Ansible variable | ENV variable |
| ---- | ----------- | ------------ |
| Gitlab Runner registration token | gitlab_runner_registration_token | GITLAB_RUNNER_REGISTRATION_TOKEN

## How to Contribute

### Adding a new role
A new role can be added to the [roles](./roles/) folder and then included into a new and/or existing playbook.

### Updating an existing role
The existing roles can be found in the [roles](./roles/) folder. To update a role, the role's tasks can be simply modified.

### External dependencies
Go to [requirements.yml](../../../requirements.yml) and [galaxy.yml](./galaxy.yml) files to add or update any external dependency.

### Add/Update new variables
Ansible variables that are datacentre specific should be added to the `group_vars` folder of the inventory.

To modify non-secret variable role defaults, go to the defaults folder of the respective role and update them. As an [example](./roles/runner/defaults/main.yml).

Finally, the secret variables are defined in the respective [Makefile](../../../resources/jobs/gitlab-runner.mk) and can be modified there. To assign proper values to these variables, please use a `PrivateRules.mak` file.

## More information

- [Ansible Using collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html)
- [Ansible Collection overview](https://github.com/ansible-collections/overview)
- [Ansible User guide](https://docs.ansible.com/ansible/latest/user_guide/index.html)
- [Ansible Developer guide](https://docs.ansible.com/ansible/latest/dev_guide/index.html)
- [Ansible Community code of conduct](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html)
## License

BSD-3.
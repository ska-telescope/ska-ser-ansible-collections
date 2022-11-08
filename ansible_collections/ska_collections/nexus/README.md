# Ansible Collection - ska_collections.nexus

Deploy Nexus OSS edition through Ansible.

## Summary

This collection deploys Nexus OSS edition using an adapted version of https://github.com/ansible-ThoTeam/nexus3-oss. The changes are found in the `./resources` directory, and are used to overwrite the `../../ansible_collections/ansible-thoteam.nexus3-oss` role.

Add to your `./PrivateRules.mak` file the required passwords for the Nexus user accounts `admin`,`gitlab`, `publisher` and `quarantiner`, the webhook url and secret key, and the APT keys and passphrases needed as follows:
```
NEXUS_VAULT_ADMIN_PASSWORD = 'whatwhat'
NEXUS_VAULT_USER_PASSWORD_GITLAB = 'whatwhat'
NEXUS_VAULT_USER_PASSWORD_PUBLISHER = 'whatwhat'
NEXUS_VAULT_EMAIL_SERVER_PASSWORD ?= 'whatwhat'
NEXUS_VAULT_USER_PASSWORD_QUARANTINER = 'whatwhat'
NEXUS_VAULT_LDAP_CONN_PASSWD = 'whatwhat'
NEXUS_WEBHOOK_URL = 'http://localhost:8080'
NEXUS_WEBHOOK_SECRET_KEY = 'whatwhat'
NEXUS_APT_BIONIC_INTERNAL_KEY = 'whatwhat'
NEXUS_APT_BIONIC_INTERNAL_KEY_PASSPHRASE = 'whatwhat'
NEXUS_APT_BIONIC_QUARENTINE_KEY = 'whatwhat'
NEXUS_APT_BIONIC_QUARENTINE_KEY_PASSPHRASE = 'whatwhat'
```

Together with an Ansible inventory, Nexus can be installed from the collections root folder using:
```
make ac-install-dependencies
make nexus install
```

## Production site

The production Nexus instance for the Central Artefact Repository is hosted at https://artefact.skatelescope.org/.  This is integrated with SKAO LDAP based authentication for administration access - all other service accounts are maintained as local users.

## Configuration

The complete configuration for the deployment is contained in [deploy.yml](./playbooks/deploy.yml).

## How to Contribute

### Adding a new role
A new role can be added to the [roles](./roles/) folder and then included into the nexus playbook in the [deploy.yml](./playbooks/deploy.yml) file.

### Updating an existing role
The existing roles can be found in the [roles](./roles/) folder and are already included into the nexus playbook in the [deploy.yml](./playbooks/deploy.yml) file. To update a role, the role's tasks can be simply modified.

This collection does have an external role dependency, `ansible-thoteam.nexus3-oss`, which can be installed using the main Makefile of this repository. To update this role, a new version may be specified in the [requirements.yml](../../../requirements.yml) and [galaxy.yml](./galaxy.yml) files.

### Add/Update new variables
Ansible variables that are datacentre specific should be added to the `host_vars` folder of the inventory.

To modify non-secret variable defaults, the [deploy.yml](./playbooks/deploy.yml) file defines them in the `vars` field of the `Nexus install` task.

Finally, the secret variables are defined in the Nexus [Makefile](../../../resources/jobs/nexus.mk) and can be modified there. To assign proper values to these variables, please use a `PrivateRules.mak` file.
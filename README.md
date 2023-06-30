# SKA Ansible Collections

This repo contains a set of [Ansible Role Collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html), that can be reused to install and/or config services.


| Collection                                                                | Description                                                                            |
| ------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| [instance_common](./ansible_collections/ska_collections/instance_common/) | VM initialization (common packages, mount volumes, etc) <br> Generate SSL Certificates |
| [docker_base](./ansible_collections/ska_collections/docker_base/)         | Install specific OCI engine                                                            |
| [logging](./ansible_collections/ska_collections/logging/)                 | Elasticsearch, Beats and Kibana roles                                                  |
| [monitoring](./ansible_collections/ska_collections/monitoring/)           | Install prometheus-based metrics services                                              |
| [minikube](./ansible_collections/ska_collections/minikube/)               | Install minikube and associated tools                                                  |
| [gitlab_runner](./ansible_collections/ska_collections/gitlab_runner/)     | Install docker-based Gitlab runner                                                     |
| [gitlab_management](./ansible_collections/ska_collections/gitlab_management/) | Manage Gitlab group                                                                |
| [ceph](./ansible_collections/ska_collections/ceph/)                       | Ceph roles                                                                             |
| [nexus](./ansible_collections/ska_collections/nexus/)                     | Install Nexus Repository                                                               |
| [gateway](./ansible_collections/ska_collections/gateway/)                 | Install gateway services (DNS, Cron jobs, OpenVPN, reverse proxy, etc)                 |
| [clusterapi](./ansible_collections/ska_collections/clusterapi/)           | Create kubernetes clusters using clusterapi                                            |
| [k8s](./ansible_collections/ska_collections/k8s/)                         | Deploy kubernetes and services to a cluster                                            |

## TLDR

The Makefile has a help target to show all available targets:

```
make ac-help
```

And all available variables:

```
make ac-vars

```

## Usage

This chapter, will explain how to use the existing collections on your local machine.

## Ansible

Tested with the current Ansible 6.5.x releases.

### Submodule

This repository is expected to be added as a submodule ([SKA Infra Machinery](https://gitlab.com/ska-telescope/sdi/ska-ser-infra-machinery)
as example) or as a subdirectory of your workspace. With this design, we make sure that every commit/change on the playbooks are environment/cloud-agnostic.


```
project - umbrella repository
│   ...
│
└─── ska-ser-ansible-collections (S)
│
└─── ...
```

The ansible playbooks expect the *ansible.cfg* file ([example](https://gitlab.com/ska-telescope/sdi/ska-ser-infra-machinery/-/blob/main/datacentres/stfc-techops/production/installation/ansible.cfg))
with all the ansible specific configurations, the ansible inventory and any playbook
variables with different values than the default ones.
Following the project structure above, it is recommended to create a directory for these files.

```
project - umbrella repository
│   ...
│
└─── ska-ser-ansible-collections (S)
│
└─── env-variables
    │   ansible.cfg
    │   inventory.yml
    │   ssh.config (optional - depend on your setup)
    └─── groups_vars
        │    all.yml
        │    ...
```

Finally, this repo has make targets to run the desired collections with all the files and configurations added with
little setup.

### Make Targets

All the targets specific to a collection such as **logging** or **oci** engine,
will be separated on their own **.mk** file on **resources/jobs** folder. Currently, we are in the process of standardizing the usage of **group_vars/host_vars** and secrets passed as **--extra-vars** to avoid having job-specific variables in generic Makefiles.

The make command must have a specific format to trigger the targets bellow, like:

```
make <collection> <job> <VARS>
```

> make

### Secret variable definition

Secrets **should not** be defined in a collection, as well as other mandatory variables. These variables should be declared as such, preferably in `defaults/main.yml`:

```
some_var: "{{ _ | mandatory('some_var definition is mandatory') }}"
```

This will ensure a playbook execution fails if they are not defined. Definition should happen in the upstream repository, as follows:

```
some_var: "{{ another_var | default_to_env('SOME_VAR') }}"
```

If you don't want environment or Makefile variables to be valid default values, simply remove `default_to_env`. If you **only** want such behavior, use:

```
some_var: "{{ _ | default_to_env('SOME_VAR') }}"
```

The value precedence respects Ansible and Makefile conventions. To integrate secret value definition with Vault, take a look at a more complete example at [SKA Infra Machinery](https://gitlab.com/ska-telescope/sdi/ska-ser-infra-machinery#secret-management). In that particular repository, the secrets are pulled from Vault into a `secrets.yml` file, and injected into the Ansible extra variables. Please reach out to [System Team](https://skao.slack.com/archives/CEMF9HXUZ) if you need Vault setup.

### Mandatory Environment Variables

| ENV variable              | Description                                                |
| ------------------------- | ---------------------------------------------------------- |
| PLAYBOOKS_ROOT_DIR        | Location where the inventories and ansible variables are   |
| PLAYBOOKS_HOSTS           | Host or ansible group that the playbook will target        |
| INVENTORY                 | Directory where mulitple inventories will be loaded from   |
| ANSIBLE_COLLECTIONS_PATHS | Path to ansible collections                                |
| ANSIBLE_CONFIG            | Path to ansible.cfg                                        |
| ANSIBLE_SSH_ARGS          | Arguments passed to ssh calls done by ansible              |
| ANSIBLE_EXTRA_VARS        | List of "--extra-vars" arguments to enrich a playbook call |

These variables must be exported to your terminal shell, passed as
command line arguments or add them to your a `PrivateRules.mak` file.

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
| [ceph](./ansible_collections/ska_collections/ceph/)                       | Ceph roles                                                                             |
| [nexus](./ansible_collections/ska_collections/nexus/)                     | Install Nexus Repository                                                               |
| [dns](./ansible_collections/ska_collections/dns/)                         | Install DNS                                                                            |
| [openvpn](./ansible_collections/ska_collections/openvpn/)                 | Install openvpn                                                                        |
| [metallb](./ansible_collections/ska_collections/metallb/)                 | Install metallb                                                                        |

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

## Tasks

### RookIO

In case you are redeploying the rook operator, you must first delete the existing rook operator deployment and the rook operator namespace.

RookIO deployment is done by invoking the `k8s-post-deployment` target with the `TAGS=rookio`. This target will deploy the rook operator for an existing Ceph cluster.

In order for this to work though, RookIO needs to be aware of the Ceph's cluster configuration. In order to do that, you need to:

1. Obtain the Ceph's cluster configuration files `ceph.conf` and `ceph.client.admin.keyring`
2. Place them in the `ceph` folder at the root of the infra machinery repo. The working folder should look like this:

        ska-ser-infra-machinery:
        └── ceph:
            ├── ceph.client.admin.keyring
            └── ceph.conf

After the configuration is done, from the base infra machinery repo, run the following command:

```
TAGS=rookio make playbooks k8s k8s-post-deployment
```
## How to Contribute

### Add/Update an Ansible Collection
A collection can be added/updated to the [ansible_collections/ska_collections](./ansible_collections/ska_collections/) folder.

### External dependencies
Add any external dependency to a collection in the respective **requirements.yml** and **galaxy.yml** files.

### Add/Update new variables
Ansible variables that are datacentre specific should be added to the `group_vars` folder of the inventory directory (*PLAYBOOKS_ROOT_DIR*).

Finally, the secret variables are defined in the respective [Makefile](./Makefile) and can be modified there. To assign proper values to these variables, please use a `PrivateRules.mak` file.
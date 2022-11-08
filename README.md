# SKA Ansible Collections

This repo contains a set of [Ansible Role Collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html), that can be reused to install and/or config services.


| Collection            | Roles                                 | Description                                               |
| --------------------- | --------------------------------------| ----------------------------------------------------------|
| instance_common       | init <br> certs                       | VM initialization (common packages, mount volumes, etc)   |
| docker_base           | containerd <br> docker <br> podman    | Install specific OCI engine                               |
| logging               | stack <br> beats <br> haproxy       | Elasticsearch, Beats and Kibana roles                    |
| monitoring            | custom_metrics <br> node_exporter <br> prometheus <br> updatehosts | Install prometheus-based metrics services |
| minikube              | minikube <br> setup <br> velero        | Install minikube and associated tools                    |
| gitlab_runner         | runner                                 | Install docker-based Gitlab runner                       |
| ceph                  | installation                          | Ceph roles                                                |
| nexus                 | common <br> nexus3-oss <br> haproxy   | Install Nexus Repository                                  |

## Usage

This chapter, will explain how to use the existing collections on your local machine.

### Requirements

* [**Ansible** v2.12.x](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

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

The table bellow, iterates all the targets available on the main Makefile.

| Target                   | Description                                       | Mandatory Variables                                         |
|--------------------------|---------------------------------------------------|-------------------------------------------------------------|
| vars                     | Print relevant shell variables                    |                                                             |
| help                     | Help guide                                        |                                                             |
| ac-ping                     | ping all hosts on a specific inventory            | INVENTORY <br> PLAYBOOKS_HOSTS |
| ac-install-dependencies  | pulls collections and roles from requirements.yml | ANSIBLE_COLLECTIONS_PATHS                                   |

All the targets specific to a collection such as **logging** or **oci** engine,
will be separated on their own **.mk** file on **resources/jobs** folder. Currently, we are in the process of standardizing the usage of **group_vars/host_vars** and secrets passed as **--extra-vars** to avoid having job-specific variables in generic Makefiles.

The make command must have a specific format to trigger the targets bellow, like:

```
make <collection> <job> <VARS>
```

| Job           | Target          | Description                                    | Dependent Targets                                |
|---------------|-----------------|------------------------------------------------|--------------------------------------------------|
| common        | init            | Update APT, install common packages and mounts volumes | |
| common        | update-hosts    |  Update host entries in a host with all the available information on the inventory | |
| common        | setup-ca        | Sets up a CA to issue self-signed certificates | |
| oci           | docker          | Install Docker       | common.init |
| oci           | podman          | Install Podman       | common.init |
| oci           | containerd      | Install containerd   | common.init |
| oci           | install         | Installs the full oci stack | common.init <br> oci.containerd <br> oci.podman <br> oci.docker |
| logging       | install         | Install elasticsearch cluster via OCI containers | common.init <br> oci.docker |
| logging       | destroy         | Destroy elasticsearch cluster | |
| logging       | update-api-keys | Create/remove elasticsearch api-keys | logging.install |
| logging       | list-api-keys   | List existing elasticsearch api-keys | logging.install |
| logging       | install-beats   | Deploy filebeat into nodes | common.init <br> oci.podman **or** oci.docker |
| logging       | destroy-beats   | Remove filebeat from nodes | |
| logging       | test_e2e        | Run e2e testing playbooks | |
| monitoring    | prometheus      | Install prometheus | common.init <br> oci.docker |
| monitoring    | thanos          | Install thanos | common.init <br> oci.docker |
| monitoring    | node-exporter   | Install node-exporter | common.init <br> oci.docker |
| monitoring    | update_metadata | Update nodes metadata for scrapers | common.init <br> oci.docker |
| monitoring    | update_scrapers | Update prometheus scrapers |common.init <br> oci.docker |
| gitlab-runner | install         | Install and register gitlab runner |  common.init <br> oci.docker  |
| gitlab-runner | destroy         | Destroy and unregister gitlab runner | |
| ceph          | install         | Install ceph | ac-install-dependencies (stackhp's cephadm) |
| ceph          | ~~destroy~~     | Destroy ceph | |
| nexus         | install         | Install Nexus Repository | common.init <br> oci.docker <br> ac-install-dependencies (ansible-thoteam.nexus3-oss)  |
| reverseproxy  | install         | Install Nginx reverse proxy and oauth2proxy | common.init <br> oci.docker |
| reverseproxy  | destroy         | Destroy Nginx reverse proxy and oauth2proxy | |

### Mandatory Environment Variables

This repo expects these environment variables to run all make targets:
* PLAYBOOKS_ROOT_DIR - Location where the inventories and ansible variables are
* PLAYBOOKS_HOSTS - Host or ansible group that the playbook will target
* INVENTORY - Directory where mulitple inventories will be loaded from
* ANSIBLE_COLLECTIONS_PATHS - Path to ansible collections
* ANSIBLE_CONFIG - Path to ansible.cfg
* ANSIBLE_SSH_ARGS - Arguments passed to ssh calls done by ansible
* ANSIBLE_EXTRA_VARS - List of "--extra-vars" arguments to enrich a playbook call

These variables must be exported to your terminal shell or passed as
command line arguments.

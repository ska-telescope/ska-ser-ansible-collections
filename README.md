# SKA Ansible Collections

This repo contains a set of [Ansible Role Collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html), that can be reused to install and/or config services.


| Collection            | Roles                                 | Description                                               |
| --------------------- | --------------------------------------| ----------------------------------------------------------|
| instance_common       | init <br> certs                       | VM initialization (common packages, mount volumes, etc)   |
| docker_base           | containerd <br> docker <br> podman    | Install specific OCI engine                               |
| elastic               | stack <br> logging <br> haproxy       | Elasticsearch and Kibana cluster roles                    |
| monitoring            | custom_metrics <br> node_exporter <br> prometheus <br> updatehosts | Install prometheus-based metrics services |
| minikube              | minikube <br> setup <br> velero        | Install minikube and associated tools                    |
| gitlab_runner         | runner                                 | Install docker-based Gitlab-runner                       |
| ceph                  | installation                          | Ceph roles                                                |

## Usage

This chapter, will explain how to use the existing collections on your local machine.

### Requirements

* [**Ansible** v2.12.x](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

### Submodule

This repository is expected to be added as a submodule ([SKA Infra Machinery](https://gitlab.com/ska-telescope/sdi/ska-ser-infra-machinery)
as example) or as a subdirectory of your workplace. With this design, we make sure that every commit/change on the
playbooks are environment/cloud-agnostic.


```
project - umbrella repository
│   ...
│
└─── ska-ser-ansible-collections (S)
│
└─── ...
```

The ansible playbooks expect the *ansible.cfg* file ([example](https://gitlab.com/ska-telescope/sdi/ska-ser-infra-machinery/-/blob/e2531bfb5a4bc8600e29b2c2c00b024fcadb0794/environments/stfc-techops/installation/ansible.cfg))
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
    │   ssf.config (optional - depend on your setup)
    └─── groups_vars
        │    all.yml
        │    ...
```

Finally, this repo has make targets to run the desired collections with all the files and configurations added with
little setup.

### Make Targets

The table bellow, iterates all the targets available on the main Makefile.

| Target                | Description                             | Mandatory Variables                                         |
|-----------------------|-----------------------------------------|-------------------------------------------------------------|
| vars                  | Print relevant shell variables          |                                                             |
| help                  | Help guide                              |                                                             |
| ac-ping               | ping all hosts on a specific inventory  | PLAYBOOKS_ROOT_DIR <br> PLAYBOOKS_HOSTS <br> ANSIBLE_CONFIG |
| ac-install-collections | pulls collections from requirements.yml | ANSIBLE_COLLECTIONS_PATHS                                   |

All the targets specific to a collection such as **elastic** or **oci** engine,
will be separated on their own **.mk** file on **resources/jobs** folder.

The make command must have a specific format to trigger the targets bellow, like:

```
make <collection> <job> <VARS>
```

| Collection | Job        | Description                                                | Role Dependency                                |
|------------|------------|------------------------------------------------------------|----------------------------------------------- |
| common     | install    | Update APT, install common packages and mounts volumes     |                                                |
| oci        | docker     | Install Docker                                             |                                                |
| oci        | podman     | Install Podman                                             |                                                |
| oci        | containerd | Install containerd                                         |                                                |
| common     | init       | Update APT <br> Install common packages <br> Mount volumes |                                                |
| common     | certs      | Generate certificates from the Terminus CA                 |                                                |
| ceph       | install    | Install ceph                                               | stackhp cephadm (run ac-install-collections)   |
| elastic    | install    | Install elasticsearch cluster via OCI containers           | instance_common.init <br> intance_common.certs <br> docker_base.docker  |
| elastic    | destroy    | Destroy elasticsearch cluster                              |                                                |
| logging    | install    | Deploy filebeat into nodes                                 |                                                |
| logging    | destroy    | Remove filebeat from nodes                                 |                                                |
| logging    | test_e2e   | Run e2e testing playbooks                                  |                                                |
| monitoring    | prometheus       | Install prometheus                                |                                                |
| monitoring    | thanos           | Install thanos                                    |                                                |
| monitoring    | node-exporter    | Install node-exporter                             |                                                |
| monitoring    | update_metadata  | Update nodes metadata for scrapers                |                                                |
| monitoring    | update_scrapers  | Update prometheus scrapers                        |                                                |
| gitlab_runner | install  | Install and register gitlab runner                        |  instance_common.init <br> docker_base.docker  |
| gitlab_runner | destroy  | Destroy and unregister gitlab runner                      |                                                |

### Mandatory Environment Variables

This repo expects these environment variables to run all make targets:
* PLAYBOOKS_ROOT_DIR
* PLAYBOOKS_HOSTS
* ANSIBLE_CONFIG

These variables must be exported to your terminal shell or passed as
command line arguments.

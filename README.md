# SKA Ansible Collections

This repo contains a set of [Ansible Role Collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html), that can be reused to install and/or config services.


| Collection      | Roles                                                                                                                       | Description                                                                                                                                                                                                                                                                                                                            |
|-----------------|-----------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| oci             | containerd <br> docker <br> podman                                                                                          | install specific OCI engine                                                                                                                                                                                                                                                                                                            |
| instance_common | init <br> certs                                                                                                             | VM initialization                                                                                                                                                                                                                                                                                                                      |
| elastic         | stack <br> haproxy <br> logging                                                                                             | Elasticsearch cluster roles                                                                                                                                                                                                                                                                                                            |
| k8s             | charts, <br> haproxy, <br> helm, <br> join, <br> k8s, <br> kubectl, <br> resources, <br> metallb ,<br> binderhub, <br> ping | default SKA helm charts <br> haproxy Kubernetes LoadBalancer <br> helm client <br> join node to HA cluster <br> Kubernetes packages <br> Kubernetes client <br> Create Namespaces and Apply Limits and Quotas <br> Load balancer for kubernetes <br> Service to share Jupyter notebooks in the cloud <br> Ping service to test ingress |

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

| Target | Description                            | Mandatory Variables                                         |
|--------|----------------------------------------|-------------------------------------------------------------|
| vars   | Print relevant shell variables         |                                                             |
| help   | Help guide                             |                                                             |
| ping   | ping all hosts on a specific inventory | PLAYBOOKS_ROOT_DIR <br> PLAYBOOKS_HOSTS <br> ANSIBLE_CONFIG |

All the targets specific to a collection such as ElasticSearch or OCI engine, 
it will be separated on their own **.mk** file on **resources/jobs** folder.

The make command must have a specific format to trigger the targets bellow, like:

```
make <collection> <job> <VARS>
```

| Collection | Job        | Description                                                | Role Dependency                               |
|------------|------------|------------------------------------------------------------|-----------------------------------------------|
| elastic    | install    | Install ElasticSearch cluster via OCI containers           | common.init <br> common.certs <br> oci.docker |
| elastic    | destroy    | Destroy ElasticSearch cluster                              |                                               |
| oci        | docker     | Install Docker                                             |                                               |
| oci        | podman     | Install Podman                                             |                                               |
| oci        | containerd | Install containerd                                         |                                               |
| common     | init       | Update APT <br> Install common packages <br> Mount volumes |                                               |
| common     | certs      | Generate certificates from the Terminus CA                 |                                               |

### Mandatory Environment Variables

This repo expects these environment variables to run all make targets:
* PLAYBOOKS_ROOT_DIR
* PLAYBOOKS_HOSTS
* ANSIBLE_CONFIG

These variables must be exported to your terminal shell or passed as 
command line arguments.

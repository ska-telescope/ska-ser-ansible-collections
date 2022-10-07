# SKA Ansible Collections

This repo contains a set of [Ansible Role Collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html), that can be reused to install and/or config toservices.


| Collection            | Roles                                 | Description                                               |
| --------------------- | --------------------------------------| ----------------------------------------------------------|
| oci                   | containerd <br> docker <br> podman    | install specific OCI engine                               |
| instance_common       | init                                  | VM initialization (common packages, mount volumes, etc)   |
| elastic               | stack                                 | install Elasticsearch cluster (container based)           |
<!-- | k8s           | charts, <br> haproxy, <br> helm, <br> join, <br> k8s, <br> kubectl, <br> resources, <br> metallb ,<br> binderhub, <br> ping | default SKA helm charts <br> haproxy Kubernetes LoadBalancer <br> helm client <br> join node to HA cluster <br> Kubernetes packages <br> Kubernetes client <br> Create Namespaces and Apply Limits and Quotas <br> Load balancer for kubernetes <br> Service to share Jupyter notebooks in the cloud <br> Ping service to test ingress | -->

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

The make command must have a specific format to trigger the targets bellow.
For example, for the ElasticSearch targets we must run:

```
$ make elastic

ElasticSearch targets - make playbooks elastic <target>:
destroy                        Destroy elastic - only the containers
help                           Show Help
install                        Install elastic

make elastic install
<output omitted>

```

```
$ make oci
OCI targets - make playbooks oci <target>:
containerd                     Install containerd
docker                         Install docker
help                           Show Help
podman                         Install podman

make oci docker
<output omitted>

```

```
$ make monitoring
Monitoring solution targets - make playbooks monitoring <target>:
help                           Show Help
lint                           Lint playbooks
node-exporter                  Install Prometheus node exporter - pass INVENTORY_FILE and NODES
server                         Install Prometheus Server
thanos                         Install Thanos query and query front-end
update_metadata                OpenStack metadata for node_exporters - pass INVENTORY_FILE all format should be OK
update_scrapers                Force update of scrapers
vars                           Variables

$ make monitoring vars
Current variable settings:
PRIVATE_VARS=extra_vars.yml
CLUSTER_KEYPAIR=
INVENTORY_FILE=/home/matteo/ska-ser-infra-machinery/environments/stfc-techops/installation/inventory.yml 
EXTRA_VARS=extra_vars.yml
ANSIBLE_COLLECTIONS_PATHS=/home/matteo/ska-ser-infra-machinery/ska-ser-ansible-collections
STACK_CLUSTER_PLAYBOOKS=
DOCKER_PLAYBOOKS=

```

### Mandatory Environment Variables

This repo expects these environment variables to run all make targets:
* PLAYBOOKS_ROOT_DIR
* PLAYBOOKS_HOSTS
* ANSIBLE_CONFIG

These variables must be exported to your terminal shell or passed as 
command line arguments.

Using the script option based on the project structured above:
```
export BASE_PATH="$(cd "$(dirname "$1")"; pwd -P)"
export PLAYBOOKS_ROOT_DIR="${BASE_PATH}/env-variables"
export ANSIBLE_CONFIG="${BASE_PATH}/env-variables/ansible.cfg"
export ANSIBLE_COLLECTIONS_PATHS="${BASE_PATH}/ska-ser-ansible-collections"
export ANSIBLE_COLLECTIONS_PATHS="${BASE_PATH}/ska-ser-ansible-collections"
export PLAYBOOKS_HOSTS="central-logging"
```

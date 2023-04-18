# Ansible Collection - ska_collections.clusterapi

This directory contains the `ska_collections.clusterapi` Ansible Collection. The collection includes roles and playbooks for `clusterapi` based Kubernetes deployments.  It is expected to work closely with the  `ska_collections.minikube` collection for building a management cluster with Minikube, and the  `ska_collections.k8s` collection for post workload cluster deployment processing and customisation.

Overall, this is a collection of helpers that facilitate the deployment of Kubernetes clusters using:

* cluster api provider openstack - https://github.com/kubernetes-sigs/cluster-api-provider-openstack

## OpenStack Integration

Enables full integration with the OpenStack platform, where the provider:

* uses Octavia for the load balancer frontend to etcd and apiserver
* uses Nova to generate workload cluster nodes based on specified flavours

## How it works

Clusterapi is an operator that works on the same princples as any other Kubernetes custom resource declarative interface.  The operator is deployed in a management cluster along with the desired infrastructure providers (OpenStack) that provide the driver interface for communicating with the specific infrastructure context.  See the clusterapi book for details https://cluster-api.sigs.k8s.io/user/concepts.html .

The user defines a collection of manifests that describe the machine and cluster layout for the desired workload cluster(s).  The manifest is then applied to the management cluster which then orchestrates the creation of the workload cluster by communicating with the infrastructure provider (OpenStack in this case), and driving the `kubeadm` configuration manager (https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/).  These manifests are templated by the `clusterctl generate cluster` command.

These templates provided by the upstream Infrastructure Provider, are not enough on their own. They need to be modified to include the wide range of configuration changes required in the context of each Infrastructure hosting (storage, networking, compute, security etc.), and the specific configuration of the resultant Kubernetes workload cluster (`kubeadm` configuration https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta3/).

Additionally, the clusterapi manifest specification enables a set of pre and post kubeadm hooks that are applied to both controlplane nodes and worker nodes in the target workload cluster.  These hooks enable customisation of the deployment to be injected into the deployment workflow.  This cannot be achieved by the `clusterctl generate cluster` flow directly, so `kustomize` (https://kustomize.io/) templates have been developed to inject the necessary changes(See: [resources/clusterapi](../../../../resources/clusterapi/kustomize) ).  These templates add in different sets of `ansible-playbook` flows for controlplane and worker nodes for each infrastructure provider, so that the hosts are customised, and the necessary baseline services are installed into the workload cluster eg: containerd mirror configs, docker, helm tools, Pod Network (Calico) etc.


## Roles and Playbooks

The enclosed roles and playbooks facilitate the creation of the management cluster, VM Images for OpenStack (uses Packer) workload cluster manifests, extracting `KUBECONFIG` and generating the workload cluster Ansible inventory.


### Roles

Each role encompasses a individual component/service/integration to be deployed in a Kubernetes cluster.  In most cases, the only input required is the `KUBECONFIG` file/path for the target cluster to apply the role to.  Note that this is the `KUBECONFIG` on the target inventory host that the Ansible role will be run against.

| Name | Description | Version | K8s Requirements |
| ---- | ----------- | ------- | --- |
| [clusterapi.calico](./roles/calico) | Install and configure Calico Pod Network |3.24.5 | 1.25.5+ |
| [clusterapi.clusterapi](./roles/clusterapi) | Install `clusterctl` | v1.3.5 | 1.25.5+ |
| [clusterapi.clusterinventory](./roles/clusterinventory) | Extract the workload cluster Ansible inventory | v1.3.5 | 1.25.5+ |
| [clusterapi.configcapo](./roles/configcapo) | Install the CAPO Infra Provider on the Management Cluster | v0.7.1 | 1.25.5+ |
| [clusterapi.containerd](./roles/containerd) | Install and configure containerd as required for CAPI | 1.6.6-1 | 1.25.5+ |
| [clusterapi.createworkload](./roles/createworkload) | Generate template and build manifest for workload cluster | N/A | 1.25.5+ |
| [clusterapi.imagebuilder](./roles/imagebuilder) | Install image-builder tools and build OS image (Packer) | master | 1.25.5+ |
| [clusterapi.kubeconfig](./roles/kubeconfig) | Extract the workload cluster `KUBECONFIG` | N/A | 1.25.5+ |

### Playbooks

Playbooks can be found in the [playbooks/](./playbooks) folder in the following files:

| Name | Description |
| ---- | ----------- |
| [calico-install.yml](./playbooks/calico-install.yml) | Install Calico Pod Network |
| [clusterapi.yml](./playbooks/clusterapi.yml) | Install and configure `cluserctl` and the CAPO provider on management cluster |
| [containerd.yml](./playbooks/containerd.yml) | Install and configure containerd |
| [docker.yml](./playbooks/docker.yml) | Install and configure Docker using `ska_collections.docker_base.docker` |
| [create-workload.yml](./playbooks/create-workload.yml) | Generate workload cluster manifests and apply |
| [destroy-workload.yml](./playbooks/destroy-workload.yml) | Destroys the workload cluster |
| [get-workload-inventory.yml](./playbooks/get-workload-inventory.yml) | Extract workload cluster Ansible inventory |
| [get-workload-kubeconfig.yml](./playbooks/get-workload-kubeconfig.yml) | Extract workload cluster `KUBECONFIG` |
| [imagebuilder.yml](./playbooks/imagebuilder.yml) | Build OS images for CAPO deployment |
| [init-hosts.yml](./playbooks/init-hosts.yml) | Initialise hosts using `ska_collections.instance_common.init` |
| [install-tools.yml](./playbooks/install-tools.yml) | Install tools such as Helm |

## Workflow

See the `make` targets in [clusterapi.mk](../../../resources/jobs/clusterapi.mk) .  These are designed to work in the context of [Infra Machinery](https://gitlab.com/ska-telescope/sdi/ska-ser-infra-machinery).

### Basic Configuration

Setup `PrivateRules.mak` - the following highlights key variables that are likely to be set.  Please carefully review the `./defaults/main.yml` of each role for further options along with [clusterapi.yml](https://gitlab.com/ska-telescope/sdi/ska-ser-infra-machinery/-/blob/main/datacentres/stfc-techops/production/installation/host_vars/clusterapi.yml).

```
DATACENTRE = stfc-techops
ENVIRONMENT = production
SERVICE = clusterapi
```

You can override all the required variables in group_vars/host_vars file as follows:

```
base_path: "{{ lookup('ansible.builtin.env', 'BASE_PATH', default='') | mandatory }}"

# Set the inventories output by clusterapi to go to the current
# inventory dir
capi_clusterinventory_output_dir: "{{ inventory_dir }}"

# Set the kubeconfig output directory to go to the resources
capi_kubeconfig_output_dir: "{{ base_path }}/resources/kubeconfig"

# Set the cluster structure
capi_cluster: <cluster name>
capi_capo_openstack_cloud_config: <path to clouds.yaml>
capi_capo_openstack_cloud: <name of the target clouds in clouds.yaml>
capi_capo_openstack_image_name: <image name>
capi_capo_controlplane_machine_flavour: <controlplane node flavour>
capi_capo_node_machine_flavour: <worker node flavour>
capi_controlplane_count: <controlplane count>
capi_worker_count: <worker node count>
capi_capo_run_kubelet_install: true

# Set the cluster's network settings
capi_capo_os_network_name: <target network name>
capi_capo_os_subnet_name: <target subnetwork name>

# Set basic k8s variables to target the workload cluster when installing services using
# the k8s collection
k8s_kubernetes_version: "{{ capi_k8s_version }}"
k8s_rook_ceph_conf_ini_file: "{{ base_path }}/ceph/ceph.conf"
k8s_rook_ceph_conf_key_ring: "{{ base_path }}/ceph/ceph.client.admin.keyring"

# This particular setting will make all `make playbooks k8s install XXX` targets
# use the workload cluster's kubeconfig
k8s_kubeconfig: "/etc/clusterapi/{{ capi_cluster }}-kubeconfig"
```
### First - Create VM Image

Make sure the appropriate OS image has been generated for the Kubernetes version being deployed.  This can be generated with:
```
$ make playbooks clusterapi clusterapi-imagebuilder PLAYBOOKS_HOSTS=management-cluster
```
Note: see [imagebuilder/defaults/main.yml](https://gitlab.com/ska-telescope/sdi/ska-ser-ansible-collections/-/blob/main/ansible_collections/ska_collections/clusterapi/roles/imagebuilder/defaults/main.yml) for the image building configuration options.

### Create management cluster

Our management cluster is a single node cluster running minikube. First we need to deploy the host, generate the inventory and then provision the management cluster:
```
make orch apply
make orch generate-inventory
```

Now, create a group in ansible and use a group_vars file, or use a host_vars file with the host's name, and add the appropriate values mentioned in "Basic Configuration". Afterwards, we can start the management cluster creation process:

```
make playbooks clusterapi build-management-cluster PLAYBOOKS_HOSTS=<management cluster>
```

This will have initialised an instance using Terraform, generated the required inventory, and then:
* Basic provisioning of host level tooling ready for Minikube
* Minikube and Kubernetes command line tools
* Built a Minikube single node cluster
* Installed clusterapi tools, initialised OpenStack Infrastructure Provider and retrieved the CAPO manifest template

Build a workload cluster, and perform post deployment customisations:
```
make playbooks clusterapi create-workload-cluster CAPI_APPLY=true PLAYBOOKS_HOSTS=<management cluster>
```

You can use the target without CAPI_APPLY=true to check the generated manifest if you want to validate it first.
```
make playbooks clusterapi create-workload-cluster PLAYBOOKS_HOSTS=<management cluster>

# Get the workload cluster kubeconfig and inventory
make playbooks clusterapi get-workload-cluster PLAYBOOKS_HOSTS=<management cluster>
```

This will have:
* Generated the workload cluster manifest and applied it to the management cluster
* Waited for the cluster to have completed deployment and become viable
* Retieved the `KUBECONFIG`
* Generated the Ansible inventory equivalent to the current workload cluster state

The last major step is to apply the post deployment customisations.  These are sourced from the `ska_collections.k8s` collection:

```
make playbooks k8s install
make playbooks k8s test
```

# Testing

## Tested with Ansible

Tested with the current Ansible 7.2.x releases.

## Included content

* `clusterapi` role for installing ClusterAPI dependencies and useful tools - clusterctl, bootstrapping the openstack provider (CAPO).

## Using this collection

Before using the collection, you need to install the collection with the `ansible-galaxy` CLI:

    ansible-galaxy collection install ska_collections.clusterapi

You can also include it in a `requirements.yml` file and install it via ansible-galax collection install -r requirements.yml` using the format:

```yaml
collections:
- name: ska_collections.clusterapi
```

Carefully review the default vars for each role before use: [eg: ./clusterapi/defaults/main.yml](./roles/clusterapi/defaults/main.yml).
Also see the [playbooks](./playbooks/) for usuage examples.


See [Ansible Using collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html) for more details.

## More information

- [Ansible Collection overview](https://github.com/ansible-collections/overview)
- [Ansible User guide](https://docs.ansible.com/ansible/latest/user_guide/index.html)
- [Ansible Developer guide](https://docs.ansible.com/ansible/latest/dev_guide/index.html)
- [Ansible Community code of conduct](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html)

## Licensing

BSD-3.

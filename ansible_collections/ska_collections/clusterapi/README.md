# Ansible Collection - ska_collections.clusterapi

This directory contains the `ska_collections.clusterapi` Ansible Collection. The collection includes roles and playbooks for `clusterapi` based Kubernetes deployments.

It is a collection of helpers that facilitate the deployment of Kubernetes clusters using:

* cluster api provider openstack - https://github.com/kubernetes-sigs/cluster-api-provider-openstack
* clusterapi provider BYOH - https://github.com/vmware-tanzu/cluster-api-provider-bringyourownhost


## OpenStack

Enables full integration with the OpenStack platform, where the provider:

* uses Octavia for the load balancer frontend to etcd and apiserver
* uses Nova to generate workload cluster nodes based on specified flavours


## BYOH

Enables deployment of Kubernetes clusters on existing baremetal and/or VMs


## How it works

Clusterapi is an operator that works on the same princples as any other custom resource declarative interface.  The operator is deployed in a management cluster along with the desired infrastructure providers (OpenStack, and BYOH) that provide the driver interface for communicating with the specific infrastructure context.  See the clusterapi book for details https://cluster-api.sigs.k8s.io/user/concepts.html .

The user defines a collection of manifests that describe the machine and cluster layout for the desired workload cluster.  The manifest is then applied to the management cluster which then orchestrates the creation of the workload cluster by communicating with the infrastructure provider, and driving the `kubeadm` configuration manager (https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/).  These manifests are templated by the `clusterctl generate cluster` command.


The clusterapi manifest specification enables a set of pre and post kubeadm hooks that are applied to both controlplane nodes and worker nodes in the target workload cluster.  These hooks enable customisation of the deployment to be injected into the deployment workflow.  This cannot be achieved by the `clusterctl generate cluster` flow directly, so `kustomize` (https://kustomize.io/) templates have been developed to inject the necessary changes(See: [resources/clusterapi](../../../../resources/clusterapi) ).  These templates add in different sets of `ansible-playbook` flows for controlplane and worker nodes for each infrastructure provider, so that the hosts are customised, and the necessary baseline services are installed into the workload cluster eg: containerd mirror configs, ingress controller, rook, metallb, storageclasses etc.


## Roles and Playbooks

The enclosed roles and playbooks facilitate the creation of the management cluster, VM Images for OpenStack (uses Packer) workload cluster manifests, and workload cluster customisation.

## Workflow

### Create management cluster



### OpenStack - Create VM Image

### BYOH - prepare hosts

### Generate and Apply Manifests


# Testing

## Tested with Ansible

Tested with the current Ansible 6.4.x releases.

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

Carefully review the default vars for each role before use: [./clusterctl/defaults/main.yml](./clusterctl/defaults/main.yml).
Also see the [playbooks](./playbooks/) for usuage examples.


See [Ansible Using collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html) for more details.

## More information

- [Ansible Collection overview](https://github.com/ansible-collections/overview)
- [Ansible User guide](https://docs.ansible.com/ansible/latest/user_guide/index.html)
- [Ansible Developer guide](https://docs.ansible.com/ansible/latest/dev_guide/index.html)
- [Ansible Community code of conduct](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html)

## Licensing

BSD-3.

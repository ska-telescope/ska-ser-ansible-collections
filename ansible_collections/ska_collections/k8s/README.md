# Ansible Collection - ska_collections.k8s

This directory contains the `ska_collections.k8s` Ansible Collection. The collection includes roles and playbooks for Kubernetes deployments.

This collection is currently maintained by [SKAO](https://www.skao.int/).

## Ansible

Tested with the current Ansible 7.2.x releases.

## Ansible Roles

Each role encompasses a individual component/service/integration to be deployed in a Kubernetes cluster.  In most cases, the only input required is the `KUBECONFIG` file/path for the target cluster to apply the role to.  Note that this is the `KUBECONFIG` on the target inventory host that the Ansible role will be run against.

| Name | Description | Version | K8s Requirements |
| ---- | ----------- | ------- | --- |
| [k8s.binderhub](./roles/binderhub) | Install and configure Binderhub | 1.0.0-0.dev.git.3025.h276be90 | 1.25.5+ |
| [k8s.cloudprovider](./roles/cloudprovider) | Install and configure OpenStack Cloud Provider | master | 1.25.5+ |
| [k8s.externaldns](./roles/externaldns) | Install and configure External DNS CoreDNS| chart 1.19.0 | 1.25.5+ |
| [k8s.ingress](./roles/ingress) | Install and configure NGINX Ingress Controller | 1.6.6 | 1.25.5+ |
| [k8s.join](./roles/join) | Bootstrap and Join nodes to a Kubernetes cluster | 1.25.5+/Ubuntu 22.04 | 1.25.5+ |
| [k8s.k8s](./roles/k8s) | Install and configure K8s OS dependencies on nodes | 1.25.5+/Ubuntu 22.04 | 1.25.5+ |
| [k8s.metallb](./roles/metallb) | Install and configure MetalLB LoadBalancer (ARP/BGP)  | 0.13.7 | 1.25.5+ |
| [k8s.metrics](./roles/metrics) | Install and configure kube-state-metrics and metrics-server | 4.11.0/ | 1.25.5+ |
| [k8s.node_labels](./roles/node_labels) | Apply labels to Kubernetes nodes | - | 1.25.5+ |
| [k8s.node_taints](./roles/node_taints) | Apply taints to Kubernetes nodes | - | 1.25.5+ |
| [k8s.ping](./roles/ping) | Install ping test endpoint /ping/ | 1.10 | 1.25.5+ |
| [k8s.rookio](./roles/rookio) | Install and configure Rook/Ceph integration and StorageClasses | release-1.10 | 1.25.5+ |
| [k8s.singlenode](./roles/singlenode) | Install and configure a singlenode K8s cluster using `kubeadm` | _ | 1.26.4+ |
| [k8s.standardprovisioner](./roles/standardprovisioner) | Install and configure hostpath provisioner and StorageClasses | v5 | 1.25.5+ |
| [k8s.velero](./roles/velero) | Install and configure Velero based K8s backup to Swift | v1.9.2 | 1.25.5+ |
| [k8s.vault](./roles/vault) | Install and configure the Vault agent injector | v0.19.0 | 1.25.5+ |

## Installation

Before using the collection, you need to install the collection with the `ansible-galaxy` CLI:

    ansible-galaxy collection install ska_collections.k8s

You can also include it in a `requirements.yml` file and install it via ansible-galaxy collection install -r requirements.yml` using the format:

```yaml
collections:
- name: ska_collections.k8s
```

## Usage

`Make` targets are available for each role/playbook combination in [k8s.mk](../../../resources/jobs/k8s.mk).

Installation playbooks for each component can be found in the [playbooks/](./playbooks) folder in the following files:

| Name | Description |
| ---- | ----------- |
| [binderhub_destroy.yml](./playbooks/binderhub_destroy.yml) | Uninstall Binderhub |
| [binderhub.yml](./playbooks/binderhub.yml) | Install Binderhub |
| [cloudprovider.yml](./playbooks/cloudprovider.yml) | Install Openstack Cloud Provider |
| [externaldns_destroy.yml](./playbooks/externaldns_destroy.yml) | Uninsall External DNS CoreDNS |
| [externaldns.yml](./playbooks/externaldns.yml) | Install External DNS CoreDNS |
| [ingress.yml](./playbooks/ingress.yml) | Install NGINX Ingress Controller |
| [k8s.yml](./playbooks/k8s.yml) | Install Kubernetes cluster with `kubeadm` |
| [metallb_destroy.yml](./playbooks/metallb_destroy.yml) | Uninstall MetalLB |
| [metallb.yml](./playbooks/metallb.yml) | Install MetalLB LoadBalancer and, if needed, modify Port Security on OpenStack Inventory for MetalLB comms|
| [metrics.yml](./playbooks/metrics.yml) | Install Containerd|
| [node_labels.yml](./playbooks/node_labels.yml) | Apply labels to Kubernetes nodes |
| [node_taints.yml](./playbooks/node_taints.yml) | Apply taints to Kubernetes nodes |
| [ping.yml](./playbooks/ping.yml) | Install ping tester endpoint |
| [rookio.yml](./playbooks/rookio.yml) | Install Rook/Ceph integration and StorageClasses |
| [standardprovisioner.yml](./playbooks/standardprovisioner.yml) | Install hostpath provisioner and StorageClasses |
| [singlenode.yml](./playbooks/singlenode.yml) | Install single node K8s cluster using `kubeadm` |
| [velero_backups.yml](./playbooks/velero_backups.yml) | Install Velero Kubernetes backup integrated with Swift |

In order to run these playbooks, it's needed to specify the Ansible Inventory location and the respective group/hosts ***target_hosts*** variable.

Install **ingress** as an example:
```
make playbooks k8s install TAGS=ingress \
  PLAYBOOKS_HOSTS=<host with cluster's kubeconfig>  \
```

Ideally, one should set `k8s_kubeconfig` in the host's `host_vars` or relevant `group_vars`. Optionally, you can target any cluster by setting the `KUBECONFIG` environment variable:

```
make playbooks k8s install TAGS=ingress \
  PLAYBOOKS_HOSTS=<cluster host> \
  KUBECONFIG=<path to a kubeconfig>
```


> To run all the playbooks then omit the `TAGS`


# Testing

## Tested with Ansible

Tested with the current Ansible 6.4.x releases.

Carefully review the default vars for each role before use: [eg: ./k8s/defaults/main.yml](./k8s/defaults/main.yml).
Also see the [playbooks](./playbooks/) for usuage examples.


See [Ansible Using collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html) for more details.

## More information

- [Ansible Collection overview](https://github.com/ansible-collections/overview)
- [Ansible User guide](https://docs.ansible.com/ansible/latest/user_guide/index.html)
- [Ansible Developer guide](https://docs.ansible.com/ansible/latest/dev_guide/index.html)
- [Ansible Community code of conduct](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html)

## Licensing

BSD-3.

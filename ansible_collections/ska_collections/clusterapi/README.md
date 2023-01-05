# Ansible Collection - ska_collections.clusterapi

This directory contains the `ska_collections.clusterapi` Ansible Collection. The collection includes roles and playbooks for `clusterapi` based Kubernetes deployments.

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

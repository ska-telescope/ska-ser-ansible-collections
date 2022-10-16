# Ansible Collection - ska_collections.minikube

This directory contains the `ska_collections.minikube` Ansible Collection. The collection includes roles and playbooks for `minikube` based Kubernetes deployments.

## Tested with Ansible

Tested with the current Ansible 6.4.x releases.

## Included content

* `setup` role for installing Minikube dependencies and useful tools - minikube, kubectl, helm, yq and k9s.
* `minikube` role for deploying an instance of minikube and haproxy with the defaults from [ska-cicd-deploy-minikube](https://gitlab.com/ska-telescope/sdi/ska-cicd-deploy-minikube).
* `velero` role for installing Velero backup manager, and scheduling the first routine backup to an OpenStack Swift based storage location.


## Using this collection

Before using the collection, you need to install the collection with the `ansible-galaxy` CLI:

    ansible-galaxy collection install ska_collections.minikube

You can also include it in a `requirements.yml` file and install it via ansible-galax collection install -r requirements.yml` using the format:

```yaml
collections:
- name: ska_collections.minikube
```

Carefully review the default vars for each role before use: [./setup/defaults/main.yml](./setup/defaults/main.yml), [./minikube/defaults/main.yml](./minikube/defaults/main.yml) and [./velero/defaults/main.yml](./velero/defaults/main.yml).
Also see the [playbooks](./playbooks/) for usuage examples.


See [Ansible Using collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html) for more details.

## More information

- [Ansible Collection overview](https://github.com/ansible-collections/overview)
- [Ansible User guide](https://docs.ansible.com/ansible/latest/user_guide/index.html)
- [Ansible Developer guide](https://docs.ansible.com/ansible/latest/dev_guide/index.html)
- [Ansible Community code of conduct](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html)

## Licensing

BSD-3.


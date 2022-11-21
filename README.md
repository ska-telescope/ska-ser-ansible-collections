# SKA Ansible Collections

This repo contains a set of [Ansible Role Collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html), that can be reused to install and/or config services.


| Collection            | Description                                               |
| --------------------- | ----------------------------------------------------------|
| [instance_common](./ansible_collections/ska_collections/instance_common/) | VM initialization (common packages, mount volumes, etc) <br> Generate SSL Certificates   |
| [docker_base](./ansible_collections/ska_collections/docker_base/)     | Install specific OCI engine                               |
| [logging](./ansible_collections/ska_collections/logging/)      | Elasticsearch, Beats and Kibana roles                    |
| [monitoring](./ansible_collections/ska_collections/monitoring/)    | Install prometheus-based metrics services |
| [minikube](./ansible_collections/ska_collections/minikube/)  | Install minikube and associated tools                    |
| [gitlab_runner](./ansible_collections/ska_collections/gitlab_runner/)   | Install docker-based Gitlab runner                       |
| [ceph](./ansible_collections/ska_collections/ceph/)  | Ceph roles                                                |
| [nexus](./ansible_collections/ska_collections/nexus/)  | Install Nexus Repository                                  |

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

<table>
    <thead>
        <tr>
            <th>Job</th>
            <th>Target</th>
            <th>Description</th>
            <th>Dependent Targets</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td rowspan=3>common</td>
            <td>init</td>
            <td>Update APT, install common packages and mounts volumes</td>
            <td></td>
        </tr>
        <tr>
            <td>update-hosts</td>
            <td>Update host entries in a host with all the available information on the inventory</td>
            <td></td>
        </tr>
        <tr>
            <td>setup-ca</td>
            <td>Sets up a CA to issue self-signed certificates</td>
            <td></td>
        </tr>
        <tr>
            <td rowspan=4>oci</td>
            <td>docker</td>
            <td>Install Docker</td>
            <td>common.init</td>
        </tr>
        <tr>
            <td>podman</td>
            <td>Install Podman</td>
            <td>common.init</td>
        </tr>
        <tr>
            <td>containerd</td>
            <td>Install containerd</td>
            <td>common.init</td>
        </tr>
        <tr>
            <td>install</td>
            <td>Installs the full oci stack</td>
            <td>common.init</td>
        </tr>
        <tr>
            <td rowspan=7>logging</td>
            <td>install</td>
            <td>Install elasticsearch cluster via OCI containers</td>
            <td>common.init <br> oci.docker</td>
        </tr>
        <tr>
            <td>destroy</td>
            <td>Destroy elasticsearch cluster</td>
            <td></td>
        </tr>     
        <tr>  
            <td>update-api-keys</td>
            <td>Create/remove elasticsearch api-keys</td>
            <td>logging.install</td>
        </tr>
        <tr>
            <td>list-api-keys</td>
            <td>List existing elasticsearch api-keys</td>
            <td>logging.install</td>
        </tr>
        <tr>
            <td>install-beats</td>
            <td>Deploy filebeat into nodes</td>
            <td>common.init <br> oci.podman/oci.docker</td>
        </tr>
        <tr>
            <td>destroy-beats</td>
            <td>Remove filebeat from nodes</td>
            <td></td>
        </tr>
        <tr>
            <td>test_e2e</td>
            <td>Run e2e testing playbooks</td>
            <td></td>
        </tr>
        <tr>
            <td rowspan=5>monitoring</td>
            <td>prometheus</td>
            <td>Install prometheus</td>
            <td>common.init <br> oci.docker</td>
        </tr>
        <tr>
            <td>thanos</td>
            <td>Install thanos</td>
            <td>common.init <br> oci.docker</td>
        </tr>
        <tr>
            <td>node-exporter</td>
            <td>Install node-exporter </td>
            <td>common.init <br> oci.docker</td>
        </tr>
        <tr>
            <td>update_metadata</td>
            <td>Update nodes metadata for scrapers</td>
            <td>common.init <br> oci.docker</td>
        </tr>
        <tr>
            <td>update_scrapers</td>
            <td>Update prometheus scrapers</td>
            <td>common.init <br> oci.docker</td>
        </tr>
        <tr>
            <td rowspan=2>gitlab-runner</td>
            <td>install</td>
            <td>Install and register gitlab runner</td>
            <td>common.init <br> oci.docker</td>
        </tr>
        <tr>
            <td>destroy</td>
            <td>Destroy and unregister gitlab runner</td>
            <td></td>
        </tr>
        <tr>
            <td rowspan=2>ceph</td>
            <td>install</td>
            <td>Install ceph</td>
            <td>ac-install-dependencies (stackhp's cephadm)</td>
        </tr>
        <tr>
            <td>destroy</td>
            <td>Destroy ceph</td>
            <td></td>
        </tr>
         <tr>
            <td>nexus</td>
            <td>install</td>
            <td>Install Nexus Repository</td>
            <td>common.init <br> oci.docker <br> ac-install-dependencies (ansible-thoteam.nexus3-oss)</td>
        </tr>
        <tr>
            <td rowspan=2>reverseproxy</td>
            <td>install</td>
            <td>Install Nginx reverse proxy and oauth2proxy</td>
            <td>common.init <br> oci.docker</td>
        </tr>
        <tr>
            <td>destroy</td>
            <td>Destroy Nginx reverse proxy and oauth2proxy</td>
            <td></td>
        </tr>
    </tbody>
</table>

### Mandatory Environment Variables

| ENV variable | Description |
| ----------- | ----- |
| PLAYBOOKS_ROOT_DIR | Location where the inventories and ansible variables are |
| PLAYBOOKS_HOSTS | Host or ansible group that the playbook will target |
| INVENTORY | Directory where mulitple inventories will be loaded from |
| ANSIBLE_COLLECTIONS_PATHS | Path to ansible collections |
| ANSIBLE_CONFIG | Path to ansible.cfg |
| ANSIBLE_SSH_ARGS | Arguments passed to ssh calls done by ansible |
| ANSIBLE_EXTRA_VARS | List of "--extra-vars" arguments to enrich a playbook call |

These variables must be exported to your terminal shell, passed as
command line arguments or add them to your a `PrivateRules.mak` file.

## How to Contribute

### Add/Update an Ansible Collection
A collection can be added/updated to the [ansible_collections/ska_collections](./ansible_collections/ska_collections/) folder.

### External dependencies
Add any external dependency to a collection in the respective **requirements.yml** and **galaxy.yml** files.

### Add/Update new variables
Ansible variables that are datacentre specific should be added to the `group_vars` folder of the inventory directory (*PLAYBOOKS_ROOT_DIR*).

Finally, the secret variables are defined in the respective [Makefile](./Makefile) and can be modified there. To assign proper values to these variables, please use a `PrivateRules.mak` file.

## License

BSD-3.
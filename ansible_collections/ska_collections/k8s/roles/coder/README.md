# Coder

This role installs the Coder application which is composed by an instance of PostgreSql and the Coder itself. The coder service, available as k8s load balancer, is an http application where user can create their own development environment which in this role is a k8s pod with one persistant volume. 

## Installation

Make sure to have a password for postgresql available in the `PrivateRules.mak` as `K8S_CODER_POSTGRESQL_PASSWORD`.

Install Coder from the ska-infra-machinery repository with: 

```
export KUBECONFIG=/path-to-kube/config
PLAYBOOKS_HOSTS=localhost make playbooks k8s install TAGS=coder
```

## Configuration

Once code is installed, you need to configure a template. Go to the service load balancer http endpoint, i.e. `http://coder.coder.svc.cluster.local/cli-auth`, and paste the token value in the `PrivateRules.mak` as `K8S_CODER_CLI_AUTH`. 
Configure coder with:

```
export KUBECONFIG=/path-to-kube/config
PLAYBOOKS_HOSTS=localhost make playbooks k8s install TAGS=coder
```


This will create a k8s job for configuring the k8s template.

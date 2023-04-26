Gitlab Runner Manifest Generation
=================================

This role generate the manifest for a GitLab Runner on Kubernetes using a customised deployment of the [GitLab Runner helm Chart](https://gitlab.com/gitlab-org/charts/gitlab-runner) and [MinIO cache](https://github.com/minio/operator). The chart is customised (using `kubectl kustomize` ) to provide caching and metrics.

To deploy the runner then a commit is required into the [manifest](https://gitlab.com/ska-telescope/ska-cicd-gitlab-k8s-agents-config) repository.

## How to use

This repo is meant to work with the [ska-ser-infra-machinery](https://gitlab.com/ska-telescope/sdi/ska-ser-infra-machinery) repository. Since it is a manifest generation there's no need to use a specific host. To generate a manifest use:

```console
PLAYBOOKS_HOSTS=localhost make playbooks gitlab-runner k8s_runner
```

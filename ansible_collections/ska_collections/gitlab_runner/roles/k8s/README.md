Gitlab Runner Manifest Generation
=================================

This role generate the manifest for a GitLab Runner on Kubernetes using a customised deployment of the [GitLab Runner helm Chart](https://gitlab.com/gitlab-org/charts/gitlab-runner) and [MinIO cache](https://github.com/minio/operator). The chart is customised (using `kubectl kustomize` ) to provide caching and metrics.

To deploy the runner then a commit is required into the [manifest](https://gitlab.com/ska-telescope/ska-cicd-gitlab-k8s-agents-config) repository.

## Generate manifest for a runner
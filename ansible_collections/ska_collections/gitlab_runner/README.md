# Ansible Collection - ska.gitlab-runner

This collection registers and runs a single gitlab-runner using docker.

## Deploy

* Runs the undeploy tasks to unregister any running gitlab-runner
* Uses a specific docker container (using the gitlab-runner image) using the `register` command to generate the gitlab-runner configuration, including tokens
* Creates a gitlab-runner container and mounts the generated configuration earlier

## Undeploy

* Uses a specific docker container (using the gitlab-runner image) using the `unregister` command
* The current gitlab-runner configuration is mounted and all present runners are unregistered
* The gitlab-runner docker container is removed
* The gitlab-runner configuration directory is removed

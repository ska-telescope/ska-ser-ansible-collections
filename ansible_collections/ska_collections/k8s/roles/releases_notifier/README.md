# Releases Notifier

This role installs the Releases Notifier application tha periodicaly monitors the given list of github and gilab repositories and notifies in slack if a new release is available.

## Installation

Take a look in to the default variables.

Make sure you specify the following variables value in base64:

- releases_notifier_github_auth_token
- releases_notifier_gitlab_auth_token
- releases_notifier_slack_hook

Install Releases Notifie from the ska-infra-machinery repository with: 

```
export KUBECONFIG=/path-to-kube/config
PLAYBOOKS_HOSTS=localhost make playbooks k8s install TAGS=releases_notifier
```

## Configuration

- **releases_notifier_github_auth_token**: github token to query repos
- **releases_notifier_gitlab_auth_token**: gitlab token to query repos
- **releases_notifier_slack_hook**: webhook of the slack channel
- **releases_notifier_interval**: ex values: 1h, 1m, 30s
- **releases_notifier_log_level**: ex values: debug, info

## Source repository

For more info on the application you can check the repository here:
- https://gitlab.com/ska-telescope/sdi/ska-ser-releases-notifier

MinIO Cache
===========

If this is a first time deployment, you need minio cache to be present in the cluster. Run `PLAYBOOKS_HOSTS=localhost make playbooks gitlab-runner show_minio` to view the template output first and investigate and ensure all the variables, namespaces, and configuration values are correct. Then, run `PLAYBOOKS_HOSTS=clusterapi make playbooks gitlab-runner deploy_minio` to deploy minio operator and a tenant. The tenant can be configured in [templates/values.yaml.j2](templates/minio-values.yaml.j2).

Then you need to have a bucket named `$GITLAB_RUNNER_MINIO_BUCKET_NAME` (default: `cache`) deployed. Note: the name of the bucket should be the same that is configured in runner deployment. Runner deployment uses the bucket name that's passed with parameter `$GITLAB_RUNNER_MINIO_BUCKET_NAME`.

The cache is configured with a restricted user who only has read and write access for the bucket defined above for runners to use. MinIO also provides an operator console ui, a tenant console ui and requires a default admin user for managing different settings if needed. So the following credentials must be set for the cache deployment in your `PrivateRules.mak` fileo or provided to make targets as arguments. _Note that, these variables do not have a default value so omitting them will fail the deployment._

```console
GITLAB_RUNNER_MINIO_ACCESS_KEY=... # Tenant Admin User
GITLAB_RUNNER_MINIO_SECRET_KEY=... # Tenant Admin User
GITLAB_RUNNER_MINIO_CONSOLE_PASSPHRASE=... # Operator Console Credentials
GITLAB_RUNNER_MINIO_CONSOLE_SALT=... # Operator Console Credentials
GITLAB_RUNNER_MINIO_CONSOLE_ACCESS_KEY=... # Tenant Console Credentials
GITLAB_RUNNER_MINIO_CONSOLE_SECRET_KEY=... # Tenant Console Credentials
GITLAB_RUNNER_MINIO_USERNAME=... # The actual user credentials for GitLab Runners
GITLAB_RUNNER_MINIO_PASSWORD=... # The actual user credentials for GitLab Runners
```

#### Accessing console interfaces

- To access operator console, run `make playbooks gitlab-runner forward_operator_console` in a new terminal session. Create a new terminal session and run `make playbooks gitlab-runner get_operator_jwt` to get the JWT Token. Go to http://localhost:9090 and use the JWT token you obtained.
- To access tenant console, run `make playbooks gitlab-runner forward_tenant_console` in a new terminal session. Use the `$GITLAB_RUNNER_MINIO_ACCESS_KEY` and `$GITLAB_RUNNER_MINIO_SECRET_KEY` tenant admin credentials to access the console. You can also use `$GITLAB_RUNNER_MINIO_USERNAME` and `$GITLAB_RUNNER_MINIO_PASSWORD` to access the restricted user.

#### Adding Lifecycle policy

To add a lifecycle policy using make targets, run `make playbooks gitlab-runner add_ilm`, this will add a lifecycle policy to delete objects older than 30 days.
In order to list the policies, you can use `make playbooks gitlab-runner list_ilms`and using the ID of the ILM, you can remove it with `make playbooks gitlab-runner delete_ilm MINIO_ILM_LIFECYCLE_ID=<id>`

### Runners

Run `make playbooks gitlab-runner k8s_runner` to view the template output, and ensure all the variables, namespaces, and configuration values are correct. Then run the pipeline to deploy a runner. 
The runners are configured to get secrets from the vault server located at `vault-test-1.skao.int`.
The secrets are:
- `stfc/gitlab-runner/s3_access_key`
- `stfc/gitlab-runner/s3_secret_key`
- `stfc/gitlab-runner/runner_registration_token`

## Help

Run `make` to get the help

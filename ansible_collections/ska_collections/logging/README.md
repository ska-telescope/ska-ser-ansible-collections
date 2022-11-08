# Ansible Collection - ska.logging

## Required variables

* **elasticsearch_dns_name**
  * Should be set to the dns name of the certificate used for the elasticsearch cluster nodes
* **logging_filebeat_elasticsearch_address**
  * Should be set to the domain or ip of the target elasticsearch cluster (preferably, the loadbalancer)

## Required secrets

* **ca_cert_password**
  * Should be set to the password used to secure the CA private key file
  * Define as: `ca_cert_password: "{{ lookup('ansible.builtin.env', 'CA_CERT_PASSWORD', default=secrets['ca_cert_password']) | mandatory }}"`
* **elasticsearch_password**
  * Should be set to the password used for the elastic user
  * Define as: `elasticsearch_password: "{{ lookup('ansible.builtin.env', 'ELASTICSEARCH_PASSWORD', default=secrets['elasticsearch_password']) | mandatory }}"`
* **kibana_viewer_password**
  * Should be set to the password used for the kibana viewer user
  * Define as: `kibana_viewer_password: "{{ lookup('ansible.builtin.env', 'KIBANA_VIEWER_PASSWORD', default=secrets['kibana_viewer_password']) | mandatory }}"`
* **elastic_haproxy_stats_password**
  * Should be set to the password to use for authentication to the HAProxy stats page
  * Define as: `elastic_haproxy_stats_password: "{{ lookup('ansible.builtin.env', 'ELASTIC_HAPROXY_STATS_PASSWORD', default=secrets['elastic_haproxy_stats_password']) | mandatory }}"`
* **logging_filebeat_elasticsearch_password**
  * Should be set to the password of the **elastic** user if `logging_filebeat_elasticsearch_auth_method: 'basic'`
    * Define as: `logging_filebeat_elasticsearch_password: "{{ elasticsearch_password }}"`
  * Should be set to the base64-decoded api-key issued by adding an entry to `elasticsearch_api_keys` and using the `update-api-keys` target of the **logging** job. We should also set `logging_filebeat_elasticsearch_auth_method: 'api-key'`
    * Define as: `logging_filebeat_elasticsearch_password: "{{ lookup('ansible.builtin.env', 'LOGGING_FILEBEAT_API_KEY', default=secrets['logging_filebeat_api_key']) | mandatory }}""`
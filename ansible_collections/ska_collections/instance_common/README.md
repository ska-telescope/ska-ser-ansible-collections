# Ansible Collection - ska.docker_base

## Required secrets

* **ca_cert_password**
  * Should be set to the password used to secure the CA private key file
  * Define as: `ca_cert_password: "{{ lookup('ansible.builtin.env', 'CA_CERT_PASSWORD', default=secrets['ca_cert_password']) | mandatory }}"`
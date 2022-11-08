# Ansible Collection - ska.reverseproxy

## Required variables

* **reverseproxy_dns_name**
  * Should be set to the dns name of the reverse proxy (also used to issue self-signed certificates when needed)
* **reverseproxy_oauth2proxy_client_id**
  * Should be set to the client id of the oauth2proxy
* **reverseproxy_oauth2proxy_tenant_id**
  * Should be set to the tenant id of the oauth2proxy

## Required secrets

* **reverseproxy_oauth2proxy_cookie_secret**
  * Should be set to the cookie secret used for the oauth2proxy
  * Define as: `reverseproxy_oauth2proxy_cookie_secret: "{{ lookup('ansible.builtin.env', 'AZUREAD_COOKIE_SECRET', default=secrets['azuread_cookie_secret']) | mandatory }}"`
* **reverseproxy_oauth2proxy_client_secret**
  * Should be set to the client secret used for the oauth2proxy
  * Define as: `reverseproxy_oauth2proxy_client_secret: "{{ lookup('ansible.builtin.env', 'AZUREAD_CLIENT_SECRET', default=secrets['azuread_client_secret']) | mandatory }}"`
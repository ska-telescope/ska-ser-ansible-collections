#!/usr/bin/python3
# -*- coding: utf-8 -*-

from __future__ import absolute_import, division, print_function

import shutil
import subprocess

# These are required for the yaml parsing to work
import ansible.module_utils.common.yaml  # noqa F401
import yaml  # noqa F401
from ansible.errors import AnsibleError
from ansible.module_utils._text import to_bytes
from ansible.module_utils.basic import AnsibleModule
from ansible.parsing.yaml.loader import AnsibleLoader

__metaclass__ = type


DOCUMENTATION = r"""
---
module: kubectl_set_env

short_description: Use kubectl to apply a set env

version_added: "1.0.0"

author:
  - Piers Harding <Piers.Harding@skao.int>

requirements:
  - kubectl (go binary)


description: Use kubectl to apply a set env

options:
  name:
    description:
      - Fully qualified name of resource.
    required: true
    type: str
  kubectl_namespace:
    description:
      - Namespace of resource - default "default".
    required: false
  envvars:
    description:
      - dictionary of environment variable NAME: VALUE pairs
    required: true
    type: dict
  state:
    description:
      - State of the resource
    choices: ["present"]
    required: false
  kubectl_extra_args:
    description:
      - Extra arguments to pass to the kubectl command line.
      - Please be aware that this passes information directly on the command
        line and it could expose sensitive data.
    default: ''
    vars:
      - name: ansible_kubectl_extra_args
    env:
      - name: K8S_AUTH_EXTRA_ARGS
  kubectl_kubeconfig:
    description:
      - Path to a kubectl config file. Defaults to I(~/.kube/config)
    default: ''
    vars:
      - name: ansible_kubectl_kubeconfig
      - name: ansible_kubectl_config
    env:
      - name: K8S_AUTH_KUBECONFIG
  kubectl_context:
    description:
      - The name of a context found in the K8s config file.
    default: ''
    vars:
      - name: ansible_kubectl_context
    env:
      - name: K8S_AUTH_CONTEXT
  kubectl_host:
    description:
      - URL for accessing the API.
    default: ''
    vars:
      - name: ansible_kubectl_host
      - name: ansible_kubectl_server
    env:
      - name: K8S_AUTH_HOST
      - name: K8S_AUTH_SERVER
  kubectl_username:
    description:
      - Provide a username for authenticating with the API.
    default: ''
    vars:
      - name: ansible_kubectl_username
      - name: ansible_kubectl_user
    env:
      - name: K8S_AUTH_USERNAME
  kubectl_password:
    description:
      - Provide a password for authenticating with the API.
      - Please be aware that this passes information directly on the command
        line and it could expose sensitive data.
        We recommend using the file based authentication options instead.
    default: ''
    vars:
      - name: ansible_kubectl_password
    env:
      - name: K8S_AUTH_PASSWORD
  kubectl_token:
    description:
      - API authentication bearer token.
      - Please be aware that this passes information directly on the command
        line and it could expose sensitive data.
        We recommend using the file based authentication options instead.
    vars:
      - name: ansible_kubectl_token
      - name: ansible_kubectl_api_key
    env:
      - name: K8S_AUTH_TOKEN
      - name: K8S_AUTH_API_KEY
  client_cert:
    description:
      - Path to a certificate used to authenticate with the API.
    default: ''
    vars:
      - name: ansible_kubectl_cert_file
      - name: ansible_kubectl_client_cert
    env:
      - name: K8S_AUTH_CERT_FILE
    aliases: [ kubectl_cert_file ]
  client_key:
    description:
      - Path to a key file used to authenticate with the API.
    default: ''
    vars:
      - name: ansible_kubectl_key_file
      - name: ansible_kubectl_client_key
    env:
      - name: K8S_AUTH_KEY_FILE
    aliases: [ kubectl_key_file ]
  ca_cert:
    description:
      - Path to a CA certificate used to authenticate with the API.
    default: ''
    vars:
      - name: ansible_kubectl_ssl_ca_cert
      - name: ansible_kubectl_ca_cert
    env:
      - name: K8S_AUTH_SSL_CA_CERT
    aliases: [ kubectl_ssl_ca_cert ]
  validate_certs:
    description:
      - Whether or not to verify the API server's SSL certificate.
        Defaults to I(true).
    default: ''
    vars:
      - name: ansible_kubectl_verify_ssl
      - name: ansible_kubectl_validate_certs
    env:
      - name: K8S_AUTH_VERIFY_SSL
    aliases: [ kubectl_verify_ssl ]

"""

# kubectl -n kube-system set env daemonset/calico-node \
# CALICO_IPV4POOL_CIDR="{{ calico_ipv4pool_cidr }}" \
# CALICO_IPV4POOL_IPIP="{{ calico_ipv4pool_ipip }}" \
# IP_AUTODETECTION_METHOD="{{ calico_ip_autodetection_method }}"

EXAMPLES = """
# Set Environment Variables on the resource
- name: Set Calico config
  ska_collections.clusterpi.kubectl_set_env:
    name: "daemonset/calico-node"
    kubectl_namespace: "kube-system"
    envvars:
      CALICO_IPV4POOL_CIDR: "{{ calico_ipv4pool_cidr }}"
      CALICO_IPV4POOL_IPIP: "{{ calico_ipv4pool_ipip }}"
      IP_AUTODETECTION_METHOD: "{{ calico_ip_autodetection_method }}"

"""

CONNECTION_TRANSPORT = "kubectl"

CONNECTION_OPTIONS = {
    "kubectl_namespace": {"switch": "--namespace", "default": "default"},
    "kubectl_kubeconfig": {"switch": "--kubeconfig", "default": ""},
    "kubectl_context": {"switch": "--context", "default": ""},
    "kubectl_host": {"switch": "--server", "default": ""},
    "kubectl_username": {"switch": "--username", "default": ""},
    "kubectl_password": {"switch": "--password", "default": ""},
    "client_cert": {"switch": "--client-certificate", "default": ""},
    "client_key": {"switch": "--client-key", "default": ""},
    "ca_cert": {"switch": "--certificate-authority", "default": ""},
    "validate_certs": {"switch": "--insecure-skip-tls-verify", "default": ""},
    "kubectl_token": {"switch": "--token", "default": ""},
    "kubectl_extra_args": {"switch": "", "default": ""},
}


class Kubectl:
    """Local kubectl based connector"""

    transport = CONNECTION_TRANSPORT
    connection_options = {
        k: CONNECTION_OPTIONS[k]["switch"] for k in CONNECTION_OPTIONS.keys()
    }
    documentation = DOCUMENTATION
    transport_cmd = None
    _shell = "/bin/sh"

    def __init__(self, params, *args, **kwargs):
        """Initialise this class"""

        # Note: kubectl runs commands as the user that started the container.
        # It is impossible to set the remote user for a kubectl connection.
        self.params = params
        self._msg = ""
        self.censored_local_cmd = ""
        self.local_cmd = ""
        cmd_arg = "{0}_command".format(self.transport)
        self.transport_cmd = kwargs.get(cmd_arg, shutil.which(self.transport))
        if not self.transport_cmd:
            raise AnsibleError(
                "{0} command not found in PATH".format(self.transport)
            )

    def _vars(self):
        """the things we want to display stringified"""

        return {
            "transport_cmd": self.transport_cmd,
            "censored_local_cmd": self.censored_local_cmd,
            "local_cmd": self.local_cmd,
            "connection_options": repr(self.connection_options),
        }

    def __repr__(self):
        """stringfy self"""

        return repr(self._vars())

    def __str__(self):
        """stringfy self"""

        return self.__repr__()

    def get_option(self, key):
        """get the option value or the default"""

        if key not in self.params:
            return CONNECTION_OPTIONS[key]["default"]
        else:
            return self.params[key]

    def _build_exec_cmd(self, cmd=""):
        """Build the local kubectl exec command to run cmd on remote_host"""

        local_cmd = [self.transport_cmd]
        censored_local_cmd = [self.transport_cmd]

        # Build command options based on doc string
        doc_yaml = AnsibleLoader(self.documentation).get_single_data()
        for key in doc_yaml.get("options"):
            if key.endswith("verify_ssl") and self.get_option(key) != "":
                # Translate verify_ssl to skip_verify_ssl, and output as string
                skip_verify_ssl = not self.get_option(key)
                local_cmd.append(
                    "{0}={1}".format(
                        self.connection_options[key],
                        str(skip_verify_ssl).lower(),
                    )
                )
                censored_local_cmd.append(
                    "{0}={1}".format(
                        self.connection_options[key],
                        str(skip_verify_ssl).lower(),
                    )
                )
            elif key in self.connection_options and self.get_option(key):
                cmd_arg = self.connection_options[key]
                local_cmd += [cmd_arg, self.get_option(key)]
                # Redact password and token from console log
                if key.endswith(("_token", "_password")):
                    censored_local_cmd += [cmd_arg, "********"]
                else:
                    censored_local_cmd += [cmd_arg, self.get_option(key)]

        extra_args_name = "{0}_extra_args".format(self.transport)
        if self.get_option(extra_args_name):
            local_cmd += self.get_option(extra_args_name).split(" ")
            censored_local_cmd += self.get_option(extra_args_name).split(" ")

        local_cmd += cmd
        censored_local_cmd += cmd

        self.local_cmd = local_cmd
        self.censored_local_cmd = censored_local_cmd

        return local_cmd, censored_local_cmd

    def exec_command(self, cmd, in_data=None, sudoable=False):
        """Run a command against Kubernetes"""

        local_cmd, censored_local_cmd = self._build_exec_cmd(cmd)

        local_cmd = [
            to_bytes(i, errors="surrogate_or_strict") for i in local_cmd
        ]
        p = subprocess.Popen(
            local_cmd,
            shell=False,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        stdout, stderr = p.communicate(in_data)

        self._msg += (
            "\n RC: {rc} / {cmd} \n "
            "STDOUT: {stdout} \n "
            "STDERR: {stderr} \n"
        ).format(rc=p.returncode,
                 cmd=repr(local_cmd),
                 stdout=stdout,
                 stderr=stderr)

        return (p.returncode, stdout, stderr)


def set_env(connector, name, envvars):
    """set environment variables on the given resource"""

    cmd = ["set", "env", name] + envvars
    rc, stdout, err = connector.exec_command(cmd)
    if not rc == 0:
        raise AnsibleError(
            "set env call failed - rc: %d out: %s err: %s"
            % (rc, stdout, err)
        )

    return rc, stdout, err


def main():
    """Launch kubectl_set_env module plugin"""

    module_args = dict(
        name=dict(type="str", required=True),
        state=dict(type="str", required=False, default="present"),
        envvars=dict(type="dict", required=True),
    )
    for arg in CONNECTION_OPTIONS.keys():
        module_args[arg] = dict(
            type="str",
            required=False,
            default=CONNECTION_OPTIONS[arg]["default"],
        )

    module = AnsibleModule(argument_spec=module_args, supports_check_mode=True)

    connector = Kubectl(module.params)

    result = {
        "params_in": connector.params,
        "connector": connector._vars(),
        "connector_msg": connector._msg,
    }

    changed = False
    try:
        rc, stdout, err = set_env(
            connector,
            module.params["name"],
            ["{k}={v}".format(k=k, v=v)
             for k, v in module.params["envvars"].items()],
        )
        changed = True
    except Exception as e:
        module.fail_json(
            msg="Failed to set_env: [%s] %s" % (connector._msg, repr(e))
        )

    result = {
        "params_in": connector.params,
        "connector": connector._vars(),
        "connector_msg": connector._msg,
    }
    if changed:
        module.exit_json(changed=changed, result=result)
    else:
        module.fail_json(
            msg="Failed to update resource: [%s] [%s] [%s] - %s"
            % (
                module.params["name"],
                module.params["type"],
                module.params["patch"],
                repr(result),
            )
        )


if __name__ == "__main__":
    main()

"""
filters.py provides custom ansible filters usable in all collections
"""
from ansible.template import AnsibleUndefined, AnsibleUndefinedVariable
from typing import Any
import os
import base64

def get_variable_context():
    context = os.environ.get("ANSIBLE_VAR_CONTEXT", None)
    if context is None:
        return {}
    
    sep = os.environ.get("ANSIBLE_VAR_CONTEXT_SEP", "CTX$")
    context_vars = {}
    for context_var in base64.b64decode(context.encode("utf-8")).decode("utf-8").split(sep):
        if context_var.strip(" "):
            var, value = context_var.split("=", 1)
            context_vars[var] = value.rstrip(" ")

    return context_vars

class FilterModule:
    """
    FilterModule provides custom filters for ansible playbooks and roles
    """
    def filters(self):
        """
        Export filters
        """
        return {"get_env": self.get_env}

    def get_env(self, value: Any, env_var: str, required: bool = True, default: Any = None):
        """
        gets the value of an environment variable or looks into other places
        """

        if not isinstance(value, AnsibleUndefined):
            return value

        var_value = os.environ.get(env_var, None)
        if var_value is not None:
            return var_value

        var_value = get_variable_context().get(env_var, default)
        if var_value is None and required:
            raise AnsibleUndefinedVariable("as")

        return var_value

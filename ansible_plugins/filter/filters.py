"""
filters.py provides custom ansible filters usable in all collections
"""
from ansible.template import AnsibleUndefined
from typing import Any
import os

def get_variable_context():
    context_path = os.environ.get("ANSIBLE_VAR_CONTEXT", None)
    if context_path is None:
        return {}
    
    context = {}
    with open(context_path, "r", encoding="utf-8") as file:
        for line in file:
            name, var = line.split("=", 1)
            context[name.strip()] = var.rstrip("\n")

    return context

class FilterModule:
    """
    FilterModule provides custom filters for ansible playbooks and roles
    """
    def filters(self):
        """
        Export filters
        """
        return {"default_to_env": self.get_env}

    def get_env(self, value: Any, env_var: str, required: bool = True, default: Any = None):
        """
        gets the value of an environment variable or looks into other places
        """
        if not isinstance(value, AnsibleUndefined):
            return value

        var_value = get_variable_context().get(env_var, os.environ.get(env_var, default))
        if var_value is None and required:
            raise ValueError(f"Unable to find default variable value")

        return var_value

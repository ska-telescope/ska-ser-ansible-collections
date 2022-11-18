from ansible.plugins.action import ActionBase
from ansible.utils.display import Display

display = Display()


class ActionModule(ActionBase):
    def run(self, tmp=None, task_vars=None):

        result = super(ActionModule, self).run(tmp, task_vars)
        module_args = self._task.args.copy()
        module_return = self._execute_module(
            module_name="wait_for_daemonset",
            module_args=module_args,
            task_vars=task_vars,
            tmp=tmp,
        )

        if "result" in module_return and "params_in" in module_return["result"]:
            display.vv(
                "PARAMS: %s" % repr(module_return["result"]["params_in"]),
                host="local",
            )
        if "result" in module_return and "connector" in module_return["result"]:
            display.vv(
                "FULL CMD: %s" % repr(module_return["result"]["connector"]["local_cmd"]),
                host="local",
            )
            display.vvv(
                "CONNECTOR MSG: %s" % repr(module_return["result"]["connector_msg"]),
                host="local",
            )

        if "failed" in module_return and module_return["failed"]:
            return module_return
        else:
            return {"changed": module_return["changed"]}

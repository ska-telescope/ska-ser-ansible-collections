"""
filters.py provides custom ansible filters usable in clusterapi's
collection playbooks and roles
"""


def get_machine_inventory(machine):
    """
    Gets a machine ansible inventory from a machine object from clusterapi
    """
    labels = machine["metadata"]["labels"]
    cluster_name = labels["cluster.x-k8s.io/cluster-name"]
    is_master = "cluster.x-k8s.io/control-plane-name" in labels
    group_name = (
        labels["cluster.x-k8s.io/control-plane-name"]
        if "cluster.x-k8s.io/control-plane-name" in labels
        else labels["cluster.x-k8s.io/deployment-name"]
    )
    machine_name = machine["status"]["nodeRef"]["name"]
    machine_ips = [
        address
        for address in machine["status"]["addresses"]
        if address["type"] == "InternalIP"
    ]
    machine_ip = machine_ips[0]["address"]
    return (
        is_master,
        cluster_name,
        group_name,
        machine_name,
        {
            "ansible_host": machine_name,
            "ansible_user": "ubuntu",
            "ansible_python_interpreter": "python3",
            "ansible_ssh_host": machine_ip,
            "ip": machine_ip,
            "metadata": {
                "component": "workload",
                "service": "clusterapi",
                "type": "master" if is_master else "worker",
                "group": group_name,
            },
        },
    )


class FilterModule:
    """
    FilterModule provides custom filters for ansible playbooks and roles
    """

    def filters(self):
        """
        Export filters
        """
        return {"get_cluster_inventory": self.get_cluster_inventory}

    def get_cluster_inventory(self, machines):
        """
        Creates an ansible inventory from a list of machines

        :param machines: List of machines to build the inventory from
        :return: Inventory object
        """
        clusters = {}
        node_groups = {}

        for machine in machines:
            (
                is_master,
                cluster_name,
                group_name,
                machine_name,
                machine_inventory,
            ) = get_machine_inventory(machine)
            if cluster_name not in clusters:
                clusters[cluster_name] = {
                    f"{cluster_name}-masters": {"children": {}},
                    f"{cluster_name}-workers": {"children": {}},
                }

            cluster_group_name = (
                f"{cluster_name}-{'masters' if is_master else 'workers'}"
            )
            clusters[cluster_name][cluster_group_name]["children"][
                group_name
            ] = None
            if group_name not in node_groups:
                node_groups[group_name] = {}

            node_groups[group_name][machine_name] = machine_inventory

        return {
            **{
                "all": {
                    "children": {
                        cluster: {"children": cluster_children}
                        for cluster, cluster_children in clusters.items()
                    }
                }
            },
            **{
                group: {"hosts": group_children}
                for group, group_children in node_groups.items()
            },
        }

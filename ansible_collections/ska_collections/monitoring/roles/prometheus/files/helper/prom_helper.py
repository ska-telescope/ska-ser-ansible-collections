import argparse
import datetime
import glob
import json
import logging
import os
import re
import socket
import sys

import yaml
from ansible.inventory.manager import InventoryManager
from ansible.parsing.dataloader import DataLoader
from ansible.vars.manager import VariableManager

EXPORTERS = {
    "node_exporter": {"name": "node", "port": 9100},
    "elasticsearch_exporter": {"name": "elasticsearch", "port": 9114},
    "ceph-mgr": {"name": "ceph_cluster", "port": 9283},
    "docker_exporter": {"name": "docker", "port": 9323},
    "docker_cadvisor": {"name": "docker_cadvisor", "port": 9324},
    "kube-proxy": {"name": "kube-proxy", "port": 10249},
}
RELABEL_KEY = "prometheus_node_metric_relabel_configs"

targets = {}
hostrelabelling = {RELABEL_KEY: []}


def check_port(address, port):
    location = (address, port)
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(0.3)
    return sock.connect_ex(location)


def generate_targets_from_inventory(inventory):
    """
    This method parses the provided inventory file and generate targets
    for prometheus by iterating over the EXPORTERS list and finding
    the matching ports in the machines.
    If the port is open, the target is generated.
    """
    sources = []
    if os.path.isdir(inventory):
        for filename in os.listdir(inventory):
            file_complete_path = os.path.join(inventory, filename)
            if (
                os.path.isfile(file_complete_path)
                and filename.endswith("yml")
                and not os.path.islink(file_complete_path)
            ):
                sources.append(file_complete_path)
    else:
        sources.append(inventory)

    for source in sources:
        loader = DataLoader()
        im = InventoryManager(loader=loader, sources=source)
        variable_manager = VariableManager(loader=loader, inventory=im)

        for host in im.get_hosts():
            try:
                print(host)
                host_vars = variable_manager.get_vars(host=host)

                hostname = host_vars["inventory_hostname"]
                host_ip = host_vars.get(
                    "ip", host_vars.get("ansible_host", None)
                )
                if host_ip is None:
                    continue

                for exporter_name, details in EXPORTERS.items():
                    result_of_check = check_port(host_ip, details["port"])
                    if result_of_check == 0:
                        print(f"{exporter_name} {hostname}:{details['port']}")
                        if exporter_name not in targets:
                            targets[exporter_name] = []
                        targets[exporter_name].append(
                            f"{host_ip}:{str(details['port'])}"
                        )
                        hostrelabelling[RELABEL_KEY].append(
                            {
                                "source_labels": ["instance"],
                                "regex": re.escape(host_ip)
                                + ":"
                                + str(details["port"]),
                                "action": "replace",
                                "target_label": "instance",
                                "replacement": hostname
                                + ":"
                                + str(details["port"]),
                            }
                        )
            except Exception as ex:
                print(ex)


def write_json_files():
    """
    This method writes the json files.
    """
    for exporter_name, export_targets in targets.items():
        json_job = [
            {
                "labels": {"job": EXPORTERS[exporter_name]["name"]},
                "targets": export_targets,
            }
        ]

        json_file = exporter_name + ".json"
        print("Generating %s" % json_file)
        with open(json_file, "w") as outfile:
            json.dump(json_job, outfile, indent=2)

    yaml_file = "%s.yaml" % RELABEL_KEY
    print("Generating %s" % yaml_file)
    with open(yaml_file, "w") as outfile:
        yaml.dump(hostrelabelling, outfile, indent=2)


start_time = datetime.datetime.now()

logging.basicConfig(level=logging.INFO)
LOG = logging.getLogger(__name__)

if os.environ.get("http_proxy") or os.environ.get("https_proxy"):
    LOG.WARN("Proxy env vars set")

parser = argparse.ArgumentParser()
parser.add_argument(
    "-i",
    "--inventory",
    help="Inventory file or folder",
)
parser.add_argument(
    "-g",
    "--glob",
    help="Inventory file or folder with glob helper for multiple directories",
)


args = parser.parse_args()

if len(sys.argv) == 1:
    parser.print_help(sys.stderr)
    sys.exit(1)

if not args.inventory and not args.glob:
    print(
        (
            "Please provide an inventory file",
            "or folder with the --inventory option",
        )
    )
    sys.exit(1)

if args.inventory:
    generate_targets_from_inventory(args.inventory)

if args.glob:
    inventories = glob.glob(args.glob)
    for inventory in inventories:
        generate_targets_from_inventory(inventory)

write_json_files()

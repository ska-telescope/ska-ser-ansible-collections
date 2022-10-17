import configparser
import re
import argparse
import json
from threading import Thread
import sys
import datetime
import socket
import time
import yaml
import os
import logging
import openstack

# openstack.enable_logging(debug=True)

NAMESPACE_PREFIX = "prom:"
EXPORTERS = {
    "node_exporter": {"name": "node", "port": 9100},
    "elasticsearch_exporter": {"name": "elasticsearch", "port": 9114},
    "ceph-mgr": {"name": "ceph_cluster", "port": 9283},
    "docker_exporter": {"name": "docker", "port": 9323},
    "docker_cadvisor": {"name": "docker_cadvisor", "port": 9324},
    "kube-proxy": {"name": "kube-proxy", "port": 10249},
}
RELABEL_KEY = "prometheus_node_metric_relabel_configs"


def check_port(address, port):
    location = (address, port)
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    return sock.connect_ex(location)


def get_novac(project_name):
    conn = openstack.connect(
        auth_url=os.environ["auth_url"],
        username=os.environ["username"],
        password=os.environ["password"],
        project_name=project_name,
        user_domain_name="default",
        project_domain_name="default",
    )
    return conn


def get_address(server):
    address = "-"
    addresses = server.to_dict()["addresses"]
    for key in addresses:
        for entry in addresses[key]:
            if "192.168.93" in entry["addr"]:
                address = entry["addr"]
                break
            address = entry["addr"]
        if address != "-":
            break
    return address


def update_openstack_metadata(update_metadata):
    """
    This method parses the provided inventory file (ansible format ini file)
    and updates the metadata on each machine in the Engage platform.

    It iterates over the EXPORTERS list and find the matching ports in the machines,
    and then adds the respective metadata to the machines

    Note: For k8s related metrics, only the loadbalancer (tagged with [loadbalancer]) machine is updated
    even though the all the cluster nodes expose the same ports!
    """
    inventory = ""
    with open(update_metadata, "r") as file:
        inventory = file.read().replace("\n", "")
    proj_list = os.environ["project_name"].split(";")

    nodes = []

    nodes2ansible = []

    for project_name in proj_list:
        novac = get_novac(project_name)
        for server in novac.compute.servers():
            server_name = str(server.to_dict()["name"]).lower()
            address = get_address(server)
            print("Processing server " + server_name + " address " + str(address))
            if address == "-" or str(address) not in inventory:
                continue

            updated_metadata = False
            for exporter_name, details in EXPORTERS.items():
                result_of_check = check_port(address, details["port"])
                try:
                    print(
                        "Update metadata on server "
                        + server_name
                        + " address "
                        + str(address)
                    )
                    if result_of_check == 0:
                        novac.compute.set_server_metadata(
                            server,
                            **{
                                NAMESPACE_PREFIX
                                + exporter_name: address
                                + ":"
                                + str(details["port"])
                            }
                        )
                    if exporter_name == "node_exporter":
                        nodes.append(address)
                    updated_metadata = True
                except Exception as e:
                    print("Problem with server " + server.id)
                    print("Error: " + repr(e))

            if updated_metadata:
                continue

            str_append = address + " ## " + server_name
            nodes2ansible.append(str_append)

    print("Generating ansible hosts file")
    with open("hosts", "w") as outfile:
        outfile.write("[nodexporter]\n")
        for node in nodes2ansible:
            outfile.write(node + "\n")

    print("*** Metadata added to the following nodes ***")
    print(nodes)


def generate_targets_from_metadata():
    """
    Generate targets by scraping the metadata of machines in Engage Platform
    This method is usually run in a cronjob in the Prometheus server
    to update the target files periodically.
    It parses the machines in the engage platform
    which have the metadata matching the EXPORTERS list
    and also generates relabellings accordingly.

    To update the metadata on the machines see :func:`update_openstack_metadata`
    """
    proj_list = os.environ["project_name"].split(";")

    targets = {}
    hostrelabelling = {RELABEL_KEY: []}

    for project_name in proj_list:
        novac = get_novac(project_name)
        for server in novac.compute.servers():
            if str(server.to_dict()["status"]) == "SHELVED_OFFLOADED":
                continue
            server_name = str(server.to_dict()["name"]).lower()
            address = get_address(server)
            if address == "-":
                continue

            for exporter_name, details in EXPORTERS.items():
                if not exporter_name in targets:
                    targets[exporter_name] = []
                try:
                    targets[exporter_name].append(
                        server.to_dict()["metadata"][NAMESPACE_PREFIX + exporter_name]
                    )

                    hostrelabelling[RELABEL_KEY].append(
                        {
                            "source_labels": ["instance"],
                            "regex": re.escape(address) + ":" + str(details["port"]),
                            "action": "replace",
                            "target_label": "instance",
                            "replacement": server_name + ":" + str(details["port"]),
                        }
                    )
                except KeyError:
                    pass

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

if (
    (os.environ.get("auth_url") is None)
    or (os.environ.get("username") is None)
    or (os.environ.get("password") is None)
    or (os.environ.get("project_name") is None)
):
    print(
        "Please provide the following environment variables: auth_url, username, password, project_name(comma separated values)"
    )
    sys.exit(1)

parser = argparse.ArgumentParser()
parser.add_argument(
    "-u",
    "--update_metadata",
    help="update metadata on openstack according to an hosts inventory file",
)
parser.add_argument(
    "-g", "--generate_targets", help="generate targets file", action="store_true"
)

args = parser.parse_args()

if len(sys.argv) == 1:
    parser.print_help(sys.stderr)
    sys.exit(1)

if args.update_metadata:
    update_openstack_metadata(args.update_metadata)
if args.generate_targets:
    generate_targets_from_metadata()

import yaml
import re
import json
import sys
import csv
import math
import argparse


def mem_st_to_float(string):
    # Convert Helm Template Memory & Storage Limits/Requests to float
    multipliers = {
        "Ki": 1024,
        "K": 1000,
        "Mi": 1024**2,
        "M": 1e6,
        "Gi": 1024**3,
        "G": 1e9,
        "Ti": 1024**4,
        "T": 1e12,
        "Pi": 1024**5,
        "P": 1e15,
        "Ei": 1024**6,
        "E": 1e18,
    }
    decimal = re.sub(
        r"([\d\.]+)(Ki|K|Mi|M|Gi|G|Ti|T|Pi|P|Ei|E)",
        lambda v: str(float(v.groups()[0]) * multipliers[v.groups()[1]]),
        string,
    )
    return int(float(decimal))


def mem_float_to_size(mem, binary=True, precision=2):
    # Convert Float values to K8s Human readable values
    if mem == 0:
        return "0"
    base = 1024 if binary else 1000
    size_name = ("", "K{}", "M{}", "G{}", "T{}", "P{}", "E{}")

    i = int(math.floor(math.log(mem, base)))
    p = math.pow(base, i)
    val = round(mem / p, precision)
    suffix = size_name[i].format("i" if binary else "")
    return f"{val:.{precision}f}{suffix}"


def cpu_to_float(string):
    # Convert Helm Template CPU Limits/Requests to float
    multipliers = {"m": 1.0 / 1000}
    decimal = re.sub(
        r"([\d\.]+)(m)",
        lambda v: str(float(v.groups()[0]) * multipliers[v.groups()[1]]),
        string,
    )
    return float(decimal)


# Default values
tcpu_requests = 0.0
tcpu_limits = 0.0
tmemory_requests = 0
tmemory_limits = 0
tstorage_requests = 0
tstorage_limits = 0

# Define Argument Parser
parser = argparse.ArgumentParser(
    description="Extract Resource Quotas from a Helm Chart, \
        generates 'resources.csv' with pod-specific values \
        and 'resources.json' with total values"
)

parser.add_argument(
    "-c,",
    "--chart",
    type=argparse.FileType("r"),
    help="Helm Chart to be processed (could be generated \
        with `helm template <chart>`)",
)

parser.add_argument(
    "--for-humans",
    help="Outputs Memory Sizes in a human readable format if set",
    action="store_true",
)

# Parse arguments
args = parser.parse_args()

# load the charts
if args.chart is None:
    charts = list(yaml.load_all(sys.stdin, Loader=yaml.FullLoader))
else:
    charts = list(yaml.load_all(args.chart, Loader=yaml.FullLoader))

with open("resources.csv", "w") as f:
    resource_writer = csv.writer(
        f, delimiter=",", quotechar='"', quoting=csv.QUOTE_MINIMAL
    )

    # Headers
    resource_writer.writerow(
        [
            "name",
            "app",
            "chart",
            "kind",
            "cpu_requests",
            "memory_requests",
            "storage_requests",
            "cpu_limits",
            "memory_limits",
            "storage_limits",
        ]
    )

    for chart in charts:
        # Ensure that chart type is dict (a valid yaml file)
        if chart is not None and type(chart) is dict:
            if (
                chart["kind"] == "Deployment"
                or chart["kind"] == "StatefulSet"
                or chart["kind"] == "Pod"
                or chart["kind"] == "DaemonSet"
                or chart["kind"] == "Job"
            ):
                chart_csv = []
                name = chart["metadata"]["name"]
                chart_csv.append(name)
                try:
                    app = chart["metadata"]["labels"]["app"]
                    chart_csv.append(app)
                except KeyError:
                    chart_csv.append("0")
                try:
                    chart_name = chart["metadata"]["labels"]["chart"]
                    chart_csv.append(chart_name)
                except KeyError:
                    chart_csv.append("0")
                kind = chart["kind"]
                chart_csv.append(kind)
                try:
                    containers = chart["spec"]["template"]["spec"][
                        "containers"
                    ]
                    pod_cpu = 0.0
                    for container in containers:
                        try:
                            container_cpu = cpu_to_float(
                                container["resources"]["requests"]["cpu"]
                            )
                            pod_cpu = pod_cpu + container_cpu
                        except Exception:
                            pass
                    chart_csv.append(pod_cpu)
                    tcpu_requests = tcpu_requests + pod_cpu
                except Exception:
                    chart_csv.append("0")
                try:
                    containers = chart["spec"]["template"]["spec"][
                        "containers"
                    ]
                    pod_memory = 0
                    for container in containers:
                        try:
                            container_memory = mem_st_to_float(
                                container["resources"]["requests"]["memory"]
                            )
                            pod_memory = pod_memory + container_memory
                        except Exception:
                            pass
                    chart_csv.append(
                        pod_memory
                    ) if not args.for_humans else chart_csv.append(
                        mem_float_to_size(pod_memory)
                    )
                    tmemory_requests = tmemory_requests + pod_memory
                except Exception:
                    chart_csv.append("0")
                try:
                    containers = chart["spec"]["template"]["spec"][
                        "containers"
                    ]
                    pod_storage = 0
                    for container in containers:
                        try:
                            container_storage = mem_st_to_float(
                                container["resources"]["requests"][
                                    "ephemeral-storage"
                                ]
                            )
                            pod_storage = pod_storage + container_storage
                        except Exception:
                            pass
                    chart_csv.append(
                        pod_storage
                    ) if not args.for_humans else chart_csv.append(
                        mem_float_to_size(pod_storage)
                    )
                    tstorage_requests = tstorage_requests + pod_storage
                except Exception:
                    chart_csv.append("0")
                try:
                    containers = chart["spec"]["template"]["spec"][
                        "containers"
                    ]
                    pod_cpu = 0.0
                    for container in containers:
                        try:
                            container_cpu = cpu_to_float(
                                container["resources"]["limits"]["cpu"]
                            )
                            pod_cpu = pod_cpu + container_cpu
                        except Exception:
                            pass
                    chart_csv.append(pod_cpu)
                    tcpu_limits = tcpu_limits + pod_cpu
                except Exception:
                    chart_csv.append("0")
                try:
                    containers = chart["spec"]["template"]["spec"][
                        "containers"
                    ]
                    pod_memory = 0
                    for container in containers:
                        try:
                            container_memory = mem_st_to_float(
                                container["resources"]["limits"]["memory"]
                            )
                            pod_memory = pod_memory + container_memory
                        except Exception:
                            pass
                    chart_csv.append(
                        pod_memory
                    ) if not args.for_humans else chart_csv.append(
                        mem_float_to_size(pod_memory)
                    )
                    tmemory_limits = tmemory_limits + pod_memory
                except Exception:
                    chart_csv.append("0")
                try:
                    containers = chart["spec"]["template"]["spec"][
                        "containers"
                    ]
                    pod_storage = 0
                    for container in containers:
                        try:
                            container_storage = mem_st_to_float(
                                container["resources"]["limits"][
                                    "ephemeral-storage"
                                ]
                            )
                            pod_storage = pod_storage + container_storage
                        except Exception:
                            pass
                    chart_csv.append(
                        pod_storage
                    ) if not args.for_humans else chart_csv.append(
                        mem_float_to_size(pod_storage)
                    )
                    tstorage_limits = tstorage_limits + pod_storage
                except Exception:
                    chart_csv.append("0")
                resource_writer.writerow(chart_csv)
    tcpu_requests = round(tcpu_requests, 2)
    tcpu_limits = round(tcpu_limits, 2)

totals = {
    "total_cpu_requests": tcpu_requests,
    "total_cpu_limits": tcpu_limits,
    "total_memory_requests": mem_float_to_size(tmemory_requests),
    "total_memory_limits": mem_float_to_size(tmemory_limits),
    "total_ephemeral_storage_requests": mem_float_to_size(tstorage_requests),
    "total_ephemeral_storage_limits": mem_float_to_size(tstorage_limits),
}

with open("resources.json", "w") as outfile:
    json.dump(totals, outfile)

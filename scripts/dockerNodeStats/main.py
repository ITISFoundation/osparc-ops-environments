import csv
import json
import logging
import os
import subprocess
from collections import defaultdict

import tqdm

# Get log level from environment variable
log_level: str = os.environ.get("LOG_LEVEL", "INFO").upper()
logging.basicConfig(level=log_level)

# Create logger
logger = logging.getLogger(__name__)

# Create handler
handler = logging.StreamHandler()

# Create formatter and add to handler
formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
handler.setFormatter(formatter)

# Add handler to logger
logger.addHandler(handler)
logger.propagate = False

# Use logger
logger.info("Starting...")
service_ids: list[str] = (
    subprocess.check_output(["docker", "service", "ls", "--format", "{{.ID}}"])
    .decode()
    .strip()
    .split("\n")
)
if service_ids == [""]:
    logger.warning("No docker services found. Exiting.")
    exit(0)
node_used_resources = defaultdict(lambda: {"NanoCPU": 0, "MemoryBytes": 0})
node_max_resources = defaultdict(lambda: {"NanoCPU": 0, "MemoryBytes": 0})

docker_node_names: list[str] = (
    subprocess.check_output(["docker", "node", "ls", "--format", "{{.Hostname}}"])
    .decode()
    .strip()
    .split("\n")
)
for node_name in docker_node_names:
    machine_max_resources = (
        subprocess.check_output(
            [
                "docker",
                "node",
                "inspect",
                node_name,
                "--format",
                "{{ .Description.Resources.NanoCPUs }} {{ .Description.Resources.MemoryBytes }}",
            ]
        )
        .decode()
        .strip()
    )
    nano_cpu, memory_bytes = machine_max_resources.split(" ")
    node_max_resources[node_name]["NanoCPU"] = int(nano_cpu)
    node_max_resources[node_name]["MemoryBytes"] = int(memory_bytes)
logger.info(
    f"Found the following node specs\n{json.dumps(node_max_resources, indent=2)}"
)
with open("dockerstats.csv", "w", newline="") as file:
    writer = csv.writer(file)
    field = ["node_name", "service_name", "cpu", "memory_gib"]
    writer.writerow(field)

    for service_id in tqdm.tqdm(service_ids):
        service_name: str = (
            subprocess.check_output(
                [
                    "docker",
                    "service",
                    "inspect",
                    "--format",
                    "{{json .Spec.Name}}",
                    service_id,
                ]
            )
            .decode()
            .strip()
        )
        resources = (
            subprocess.check_output(
                [
                    "docker",
                    "service",
                    "inspect",
                    "--format",
                    "{{json .Spec.TaskTemplate.Resources}}",
                    service_id,
                ]
            )
            .decode()
            .strip()
        )
        current_state: str = (
            subprocess.check_output(
                [
                    "docker",
                    "service",
                    "ps",
                    "--format",
                    "{{json .CurrentState}}",
                    service_id,
                ]
            )
            .decode()
            .strip()
        )
        if "Running" not in current_state:
            logger.warning(
                f"Service {service_name} has current-state != `running`. Ignoring it."
            )
            continue
        node_ids: list[str] = (
            subprocess.check_output(
                [
                    "docker",
                    "service",
                    "ps",
                    "--filter",
                    "desired-state=running",
                    "--format",
                    "{{.Node}}",
                    service_id,
                ]
            )
            .decode()
            .strip()
            .split("\n")
        )
        logger.debug(
            f"service_id {service_id} --> node_id {node_ids} (len {len(node_ids)})"
        )
        resources_dict = json.loads(resources)  # Parse the resources as a dictionary

        if "Limits" not in resources_dict and "Reservations" in resources_dict:
            logger.warning(
                f"Reservations set but not limits. Please audit this docker service: {service_id} / {service_name}"
            )
        if "Limits" not in resources_dict and "Reservations" not in resources_dict:
            logger.warning(
                f"No limits set. Please audit this docker service: {service_id} / {service_name}"
            )
        if "Limits" in resources_dict:
            if "Reservations" in resources_dict:
                if resources_dict["Limits"].get("NanoCPUs", 0) != resources_dict[
                    "Reservations"
                ].get("NanoCPUs", 0):
                    logger.warning(
                        f"CPU Limits != Reservations. Please audit this docker service: {service_id} / {service_name}"
                    )
                if resources_dict["Limits"].get("MemoryBytes", 0) != resources_dict[
                    "Reservations"
                ].get("MemoryBytes", 0):
                    logger.warning(
                        f"Memory Limits != Reservations. Please audit this docker service: {service_id} / {service_name}"
                    )
            for node in node_ids:
                logger.debug(f"node {node}")
                writer.writerow(
                    [
                        node,
                        service_name,
                        resources_dict["Limits"].get("NanoCPUs", 0) * 1 / 1000000000,
                        resources_dict["Limits"].get("MemoryBytes", 0) / 1073741824,
                    ]
                )
                node_used_resources[node]["NanoCPU"] += resources_dict["Limits"].get(
                    "NanoCPUs", 0
                )
                node_used_resources[node]["MemoryBytes"] += resources_dict[
                    "Limits"
                ].get("MemoryBytes", 0)


results_dict = {}
for node_id, resources in node_used_resources.items():
    results_dict[node_id] = {
        "cpu_used": resources["NanoCPU"] * 1 / 1000000000,
        "cpu_total": node_max_resources[node_id]["NanoCPU"] * 1 / 1000000000,
        "mem_used_gib": resources["MemoryBytes"] / 1073741824,
        "mem_total_gib": node_max_resources[node_id]["MemoryBytes"] / 1073741824,
    }
logger.info(
    "FYI: In the display below, we compare available resources on the machines with docker service limits. Docker service limits can exceed available machine resource limits if they are not identical to the docker service reservations."
)
with open("dockerstats.json", "w") as jsonfile:
    jsonfile.write(json.dumps(results_dict, indent=2))
logger.info(f"Results: \n{json.dumps(results_dict,indent=2)}")

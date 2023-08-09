import csv
import json
import logging
import os
from collections import defaultdict

import tqdm
from sh import docker

# Get log level from environment variable
log_level: str = os.environ.get("LOG_LEVEL", "WARNING").upper()
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

if __name__ == "__main__":
    logger.info(
        "This script creates the outputfiles dockerstats.json and dockerstats.csv"
    )
    logger.info("Starting...")
    ###############################################################
    service_ids = [
        x for x in docker.service.ls("--format", "{{.ID}}").split("\n") if x != ""
    ]
    logger.debug(f"service_ids: {service_ids}")
    if service_ids == [""]:
        logger.warning("No docker services found. Exiting.")
        exit(0)
    node_used_resources_limits = defaultdict(lambda: {"NanoCPU": 0, "MemoryBytes": 0})
    node_used_resources_reservations = defaultdict(
        lambda: {"NanoCPU": 0, "MemoryBytes": 0}
    )
    node_max_resources = defaultdict(lambda: {"NanoCPU": 0, "MemoryBytes": 0})

    docker_node_names = [
        x for x in docker.node.ls("--format", "{{.Hostname}}").split("\n") if x != ""
    ]

    for node_name in docker_node_names:
        machine_max_resources = [
            x
            for x in docker.node.inspect(
                node_name,
                "--format",
                "{{ .Description.Resources.NanoCPUs }} {{ .Description.Resources.MemoryBytes }}",
            ).split("\n")
            if x != ""
        ][0]
        logger.debug(f"machine_max_resources {machine_max_resources}")
        nano_cpu, memory_bytes = machine_max_resources.split(" ")
        node_max_resources[node_name]["NanoCPU"] = int(nano_cpu)
        node_max_resources[node_name]["MemoryBytes"] = int(memory_bytes)
    logger.info(
        f"Found the following node specs\n{json.dumps(node_max_resources, indent=2)}"
    )
    with open("dockerstats.csv", "w", newline="") as file:
        writer = csv.writer(file)
        field = [
            "node_name",
            "service_name",
            "cpu_limit",
            "memory_gib_limit",
            "cpu_reservation",
            "memory_gib_reservation",
        ]
        writer.writerow(field)

        for service_id in tqdm.tqdm(service_ids):
            service_name = [
                x
                for x in docker.service.inspect(
                    "--format", "{{json .Spec.Name}}", service_id
                ).split("\n")
                if x != ""
            ][0]
            logger.debug(f"service_name {service_name}")
            service_resources = [
                x
                for x in docker.service.inspect(
                    "--format", "{{json .Spec.TaskTemplate.Resources}}", service_id
                ).split("\n")
                if x != ""
            ][0]
            logger.debug(f"service_resources {service_resources}")
            current_state = [
                x
                for x in docker.service.ps(
                    "--format", "{{json .CurrentState}}", service_id
                ).split("\n")
                if x != ""
            ]
            logger.debug(f"current_state {current_state}")
            if not current_state or "Running" not in current_state[0]:
                logger.warning(
                    f"Service {service_name} has current-state != `running`. Ignoring it."
                )
                continue
            node_ids = [
                x
                for x in docker.service.ps(
                    "--filter",
                    "desired-state=running",
                    "--format",
                    "{{.Node}}",
                    service_id,
                ).split("\n")
                if x != ""
            ]
            logger.debug(
                f"service_id {service_id} --> node_id {node_ids} (len {len(node_ids)})"
            )
            resources_dict = json.loads(
                service_resources
            )  # Parse the resources as a dictionary
            logger.debug(f"resources_dict {resources_dict}")

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
                else:
                    resources_dict["Reservations"] = {"NanoCPUs": 0, "MemoryBytes": 0}
                for node in node_ids:
                    logger.debug(f"node {node}")
                    writer.writerow(
                        [
                            node,
                            service_name,
                            resources_dict["Limits"].get("NanoCPUs", 0)
                            * 1
                            / 1000000000,
                            resources_dict["Limits"].get("MemoryBytes", 0) / 1073741824,
                            resources_dict["Reservations"].get("NanoCPUs", 0)
                            * 1
                            / 1000000000,
                            resources_dict["Reservations"].get("MemoryBytes", 0)
                            / 1073741824,
                        ]
                    )
                    node_used_resources_limits[node]["NanoCPU"] += resources_dict[
                        "Limits"
                    ].get("NanoCPUs", 0)
                    node_used_resources_limits[node]["MemoryBytes"] += resources_dict[
                        "Limits"
                    ].get("MemoryBytes", 0)
                    node_used_resources_reservations[node]["NanoCPU"] += resources_dict[
                        "Reservations"
                    ].get("NanoCPUs", 0)
                    node_used_resources_reservations[node][
                        "MemoryBytes"
                    ] += resources_dict["Reservations"].get("MemoryBytes", 0)

    results_dict = {"Limits": {}, "Reservations": {}}
    for node_id, resources in node_used_resources_limits.items():
        results_dict["Limits"][node_id] = {
            "cpu_used": resources["NanoCPU"] * 1 / 1000000000,
            "cpu_total": node_max_resources[node_id]["NanoCPU"] * 1 / 1000000000,
            "mem_used_gib": resources["MemoryBytes"] / 1073741824,
            "mem_total_gib": node_max_resources[node_id]["MemoryBytes"] / 1073741824,
        }
    for node_id, resources in node_used_resources_reservations.items():
        results_dict["Reservations"][node_id] = {
            "cpu_used": resources["NanoCPU"] * 1 / 1000000000,
            "cpu_total": node_max_resources[node_id]["NanoCPU"] * 1 / 1000000000,
            "mem_used_gib": resources["MemoryBytes"] / 1073741824,
            "mem_total_gib": node_max_resources[node_id]["MemoryBytes"] / 1073741824,
        }
    with open("dockerstats.json", "w") as jsonfile:
        jsonfile.write(json.dumps(results_dict, indent=2, sort_keys=True))
    print(f"Results: \n{json.dumps(results_dict,indent=2,sort_keys=True)}")

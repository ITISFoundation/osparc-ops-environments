import csv
import json
import logging
import os
import sys
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
    logger.debug("service_ids: %s", service_ids)
    if service_ids == [""]:
        logger.warning("No docker services found. Exiting.")
        sys.exit(0)
    node_max_resources = defaultdict(lambda: {"cpu": 0, "memory_gib": 0})

    docker_node_names = [
        x for x in docker.node.ls("--format", "{{.Hostname}}").split("\n") if x != ""
    ]

    for node_name in docker_node_names:
        machine_max_resources = json.loads(
            docker.node.inspect(
                node_name,
                "--format",
                "json",
            )
        )[0]["Description"]["Resources"]

        node_max_resources[node_name]["cpu"] = (
            int(machine_max_resources["NanoCPUs"]) * 1 / 1000000000
        )
        node_max_resources[node_name]["memory_gib"] = (
            int(machine_max_resources["MemoryBytes"]) / 1073741824
        )
        if "GenericResources" in machine_max_resources.keys():
            for item in machine_max_resources["GenericResources"]:
                kind = item["DiscreteResourceSpec"]["Kind"]
                value = item["DiscreteResourceSpec"]["Value"]
                node_max_resources[node_name][kind] = int(value)

    logger.info(
        "Found the following node specs\n %s", json.dumps(node_max_resources, indent=2)
    )

    node_used_resources_limits = defaultdict(lambda: {"cpu": 0, "memory_gib": 0})
    node_used_resources_reservations = defaultdict(lambda: {"cpu": 0, "memory_gib": 0})
    with open("dockerstats.csv", "w", encoding="UTF8", newline="") as file:
        writer = csv.writer(file)
        resource_names = {
            key for inner_dict in node_max_resources.values() for key in inner_dict
        }
        csv_header_static = [
            "node_name",
            "service_name",
        ]
        csv_header_dynamic = [name + "__Limits" for name in resource_names] + [
            name + "__Reservations" for name in resource_names
        ]
        csv_header = csv_header_static + csv_header_dynamic
        logger.debug("csv_header %s", csv_header)
        writer.writerow(csv_header)
        for service_id in tqdm.tqdm(service_ids):
            service_name = [
                x
                for x in docker.service.inspect(
                    "--format", "{{json .Spec.Name}}", service_id
                ).split("\n")
                if x != ""
            ][0]
            logger.debug("service_name %s", service_name)
            service_resources = [
                x
                for x in docker.service.inspect(
                    "--format", "{{json .Spec.TaskTemplate.Resources}}", service_id
                ).split("\n")
                if x != ""
            ][0]
            logger.debug("service_resources %s", service_resources)
            current_state = [
                x
                for x in docker.service.ps(
                    "--format", "{{json .CurrentState}}", service_id
                ).split("\n")
                if x != ""
            ]
            logger.debug("current_state %s", current_state)
            if not current_state or "Running" not in current_state[0]:
                logger.warning(
                    "Service %s has current-state != `running`. Ignoring it.",
                    service_name,
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
            resources_dict = json.loads(
                service_resources
            )  # Parse the resources as a dictionary

            if "Limits" not in resources_dict and "Reservations" in resources_dict:
                logger.warning(
                    "Reservations set but not limits. Please audit this docker service: %s, %s",
                    service_id,
                    service_name,
                )
            if "Limits" not in resources_dict and "Reservations" not in resources_dict:
                logger.warning(
                    "No limits set. Please audit this docker service: %s, %s",
                    service_id,
                    service_name,
                )
            if "Limits" in resources_dict:
                if "Reservations" in resources_dict:
                    if resources_dict["Limits"].get("NanoCPUs", 0) != resources_dict[
                        "Reservations"
                    ].get("NanoCPUs", 0):
                        logger.warning(
                            "CPU Limits != Reservations. Please audit this docker service %s, %s",
                            service_id,
                            service_name,
                        )
                    if resources_dict["Limits"].get("MemoryBytes", 0) != resources_dict[
                        "Reservations"
                    ].get("MemoryBytes", 0):
                        logger.warning(
                            "Memory Limits != Reservations. Please audit this docker service: %s, %s",
                            service_id,
                            service_name,
                        )
                else:
                    resources_dict["Reservations"] = {"NanoCPUs": 0, "MemoryBytes": 0}
                for key in resources_dict:
                    resources_dict[key]["cpu"] = (
                        resources_dict[key].get("NanoCPUs", 0) * 1 / 1000000000
                    )
                    resources_dict[key]["memory_gib"] = (
                        resources_dict[key].get("MemoryBytes", 0) / 1073741824
                    )
                    if "GenericResources" in resources_dict[key]:
                        for resource in resources_dict[key]["GenericResources"]:
                            value = resource["DiscreteResourceSpec"]["Value"]
                            kind = resource["DiscreteResourceSpec"]["Kind"]
                            resources_dict[key][kind] = value
                            logger.debug(
                                "GenericResources - kind %s, value %s", kind, value
                            )
                        resources_dict[key].pop("GenericResources", None)
                    resources_dict[key].pop("NanoCPUs", None)
                    resources_dict[key].pop("MemoryBytes", None)
                    for node in node_ids:
                        logger.debug("node %s", node)
                        static_data_csv = [node, service_name]
                        dynamic_data_csv = []
                        for i in range(len(csv_header_dynamic)):
                            item = csv_header_dynamic[i]
                            if "__Limits" in item:
                                resource_name = item.split("__Limits")[0]
                                dynamic_data_csv.append(
                                    resources_dict["Limits"][resource_name]
                                    if resource_name in resources_dict["Limits"].keys()
                                    else 0
                                )
                                if (
                                    resource_name
                                    not in node_used_resources_limits[node].keys()
                                ):
                                    node_used_resources_limits[node][resource_name] = 0
                                node_used_resources_limits[node][
                                    resource_name
                                ] += resources_dict["Limits"].get(resource_name, 0)
                            if "__Reservations" in item:
                                resource_name = item.split("__Reservations")[0]
                                dynamic_data_csv.append(
                                    resources_dict["Reservations"][resource_name]
                                    if resource_name
                                    in resources_dict["Reservations"].keys()
                                    else 0
                                )
                                if (
                                    resource_name
                                    not in node_used_resources_reservations[node].keys()
                                ):
                                    node_used_resources_reservations[node][
                                        resource_name
                                    ] = 0
                                node_used_resources_reservations[node][
                                    resource_name
                                ] += resources_dict["Reservations"].get(
                                    resource_name, 0
                                )
                        data_csv = static_data_csv + dynamic_data_csv
                        logger.debug("data_csv %s", data_csv)
                        writer.writerow(data_csv)

    results_dict = {"Limits": {}, "Reservations": {}}

    for node_id, resources in node_used_resources_limits.items():
        results_dict["Limits"][node_id] = {
            resource + "_services": resources[resource] for resource in resources.keys()
        } | {
            resource + "_machine": node_max_resources[node_id][resource]
            if resource in node_max_resources[node_id].keys()
            else 0
            for resource in resources.keys()
        }
    for node_id, resources in node_used_resources_reservations.items():
        results_dict["Reservations"][node_id] = {
            resource + "_services": resources[resource] for resource in resources.keys()
        } | {
            resource + "_machine": node_max_resources[node_id][resource]
            if resource in node_max_resources[node_id].keys()
            else 0
            for resource in resources.keys()
        }
    with open("dockerstats.json", "w") as jsonfile:
        jsonfile.write(json.dumps(results_dict, indent=2, sort_keys=True))
    print(f"Results: \n{json.dumps(results_dict,indent=2,sort_keys=True)}")

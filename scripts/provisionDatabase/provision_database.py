import json
import logging
import os
from pathlib import Path

# import sqlalchemy as db
from dotenv import load_dotenv
from pytest_simcore.docker_registry import _pull_push_service

dotenv_path = Path(".env")
load_dotenv(dotenv_path=dotenv_path)

logging.basicConfig(level=logging.DEBUG)

USERNAME = "test@example.org"
REMOTE_REGISTRY_PREFIX = os.environ.get("SIMCORE_DOCKER_REGISTRY")
LOCAL_REGISTRY = os.environ.get("REGISTRY_DOMAIN")
json_schema_path = Path("osparc-simcore/api/specs/common/schemas/node-meta-v0.0.1.json")


servicesList = {
    "sleeper": "2.1.1",
    "sleeper": "2.1.3",
    "sleeper": "2.1.4",
    "jupyter-base-notebook": "2.14.0",
    "jupyter-r-notebook": "2.14.0",
}


cmd_string = (
    "echo "
    + os.environ.get("SERVICES_PASSWORD")
    + " | docker login "
    + os.environ.get("REGISTRY_DOMAIN")
    + " --username "
    + os.environ.get("SERVICES_USER")
    + " --password-stdin"
)
logging.info("Running cmd command for docker login...")
os.system(cmd_string)

node_schema = json.load(json_schema_path.open())
for key in servicesList.keys():
    logging.info("Pulling and pushing service: %s", key)
    _pull_push_service(
        REMOTE_REGISTRY_PREFIX + "/" + key,
        servicesList[key],
        LOCAL_REGISTRY,
        node_schema,
        USERNAME,
    )

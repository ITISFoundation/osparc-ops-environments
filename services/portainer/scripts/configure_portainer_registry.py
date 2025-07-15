import logging
import os
from enum import Enum
from typing import TypedDict

import requests
from tenacity import retry

logger = logging.getLogger(__name__)


# https://app.swaggerhub.com/apis/portainer/portainer-ce/2.27.6#/portainer.Registry
class RegistryType(Enum):
    DOCKER_HUB = 6


class Registry(TypedDict):
    Id: int
    Name: str
    URL: str
    Authentication: bool
    Username: str
    Type: RegistryType


@retry
def get_portainer_api_auth_token(
    portainer_api_url: str, portainer_username: str, portainer_password: str
) -> str:
    # https://app.swaggerhub.com/apis/portainer/portainer-ce/2.27.6#/auth/AuthenticateUser
    response = requests.post(
        f"{portainer_api_url}/auth",
        # https://app.swaggerhub.com/apis/portainer/portainer-ce/2.27.6#/auth.authenticatePayload
        json={"Username": portainer_username, "Password": portainer_password},
    )

    try:
        response.raise_for_status()
    except requests.HTTPError as e:
        logger.error("Failed to authenticate with Portainer API: %s", e.response.text)
        raise

    return response.json()["jwt"]


@retry
def get_registries(portainer_api_url: str, auth_token: str) -> list[Registry]:
    # https://app.swaggerhub.com/apis/portainer/portainer-ce/2.27.6#/registries/RegistryList
    response = requests.get(
        f"{portainer_api_url}/registries",
        headers={"Authorization": f"Bearer {auth_token}"},
    )

    try:
        response.raise_for_status()
    except requests.HTTPError as e:
        logger.error("Failed to fetch registries: %s", e.response.text)
        raise

    return response.json()


@retry
def create_authenticated_dockerhub_registry(
    portainer_api_url: str,
    auth_token: str,
    dockerhub_username: str,
    dockerhub_password: str,
    registry_name: str = "IT'IS Foundation",
) -> None:
    # https://app.swaggerhub.com/apis/portainer/portainer-ce/2.27.6#/registries/RegistryCreate
    response = requests.post(
        f"{portainer_api_url}/registries",
        headers={"Authorization": f"Bearer {auth_token}"},
        # https://app.swaggerhub.com/apis/portainer/portainer-ce/2.27.6#/registries.registryCreatePayload
        json={
            "name": registry_name,
            "url": "docker.io",
            "authentication": True,
            "username": dockerhub_username,
            "password": dockerhub_password,
            "type": RegistryType.DOCKER_HUB.value,
        },
    )

    try:
        response.raise_for_status()
    except requests.HTTPError as e:
        logger.error(
            "Failed to create authenticated Docker Hub registry: %s", e.response.text
        )
        raise

    return response.json()


def main():
    logger.info("Configuring Portainer registries...")

    portainer_username = os.environ["SERVICES_USER"]
    portainer_password = os.environ["SERVICES_PASSWORD"]
    portainer_api_url = os.environ["PORTAINER_URL"] + "/api"

    dockerhub_username = os.environ["DOCKER_HUB_LOGIN"]
    dockerhub_password = os.environ["DOCKER_HUB_PASSWORD"]

    portainer_jwt_token = get_portainer_api_auth_token(
        portainer_api_url, portainer_username, portainer_password
    )

    registries = get_registries(portainer_api_url, portainer_jwt_token)

    if not any(
        r["Type"] == RegistryType.DOCKER_HUB.value and r["Authentication"] is True
        for r in registries
    ):
        logging.info("Creating authenticated Docker Hub registry in Portainer...")
        create_authenticated_dockerhub_registry(
            portainer_api_url,
            portainer_jwt_token,
            dockerhub_username,
            dockerhub_password,
        )
    else:
        logging.info("Portainer already has an authenticated Docker Hub registry.")

    logging.info("Portainer registries configuration completed.")


def configure_logging():
    logging.basicConfig(
        level=logging.INFO,
    )


if __name__ == "__main__":
    configure_logging()
    main()
